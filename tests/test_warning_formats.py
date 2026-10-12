"""GUI の実際の警告メソッドと日英の翻訳文字列で型の整合を検証する。"""
from pathlib import Path
import subprocess
import tempfile
ROOT = Path(__file__).resolve().parents[1]
s = (ROOT / "Sources/Controllers/ControllerG.swift").read_text()
methods = []
for marker in ["func showPageSkippedWarning(", "func showWhitePageWarning("]:
    start = s.index(marker)
    end = s.index("{", start) + 1
    depth = 1
    while depth:
        depth += (s[end] == "{") - (s[end] == "}")
        end += 1
    methods.append(s[start:end])
code = '''import Foundation
var translations: [String:String] = [:]
func NSLocalizedString(_ key:String,comment:String)->String { translations[key] ?? key }
class Probe {
var output = ""
func appendOutputAndScroll(_ text:String,quiet:Bool) { output += text }
METHODS
}
@main struct Test {
static func main() {
for path in CommandLine.arguments.dropFirst() {
 translations = NSDictionary(contentsOfFile:path) as! [String:String]
 for pages in [[2],[1,3]] {
  let p=Probe();p.showPageSkippedWarning(pages);p.showWhitePageWarning(pages)
  for page in pages { precondition(p.output.contains(String(page))) }
 }
}
print("空白ページ警告: 単一・複数ページ、日英の4ケース成功")
}}
'''.replace("METHODS", "\n".join(methods))
with tempfile.TemporaryDirectory(prefix="warning-regression-") as directory:
    p=Path(directory)
    (p/"Test.swift").write_text(code)
    subprocess.run(["swiftc","-parse-as-library",str(p/"Test.swift"),"-o",str(p/"test")],check=True)
    subprocess.run([str(p/"test"),*[str(ROOT/"Resources"/locale/"Localizable.strings") for locale in ["ja.lproj","en.lproj"]]],check=True,timeout=10)
