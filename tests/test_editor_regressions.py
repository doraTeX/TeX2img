"""実際の編集メソッドを AppKit 上で実行する。Undo・色付け・設定UIはスタブ。"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
def extract_method(source, marker):
    text = source.read_text()
    start = text.index(marker)
    end = text.index("{", start) + 1
    depth = 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]

method = extract_method(ROOT / 'Sources/Editor/TeXTextView.swift', "@IBAction func doCommentOrIndent(")
template = (ROOT / "tests/EditorRegression.swift.in").read_text()
# The tab width the method reads goes through the same check as the settings.
helpers = (ROOT / 'Sources/Extensions/Foundation/NSDictionary-Extension.swift').read_text()
helper = helpers[helpers.index("func validTabWidth("):]
helper = helper[:helper.index("\n}\n") + 3]
with tempfile.TemporaryDirectory(prefix="editor-regression-") as directory:
    path = Path(directory)
    (path / "Test.swift").write_text(template.replace("__METHOD__", method).replace("__HELPERS__", helper))
    sources = [str(ROOT / p) for p in ['Sources/Extensions/Foundation/String-Extension.swift', 'Sources/NSString/NSString-Extension.swift']]
    subprocess.run(["swiftc", "-parse-as-library", str(path / "Test.swift"), *sources, "-o", str(path / "test")], check=True)
    subprocess.run([str(path / "test")], timeout=10, check=True)
