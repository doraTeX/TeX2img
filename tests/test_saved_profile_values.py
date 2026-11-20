"""保存したプロファイルの数値と色の読み方を実装そのものでコンパイルして確かめる（アプリは起動しない）。

プロファイルにはどんな数でも入り得る。窓枠は有限で大きさのあるものだけを使い，フォントの大きさは有限の正の数の
ときだけ使い（ほかは既定の 13pt），タブ幅は設定と同じ 1〜100 にそろえ，旧形式の色は成分が有限の数でなければ
色としない（呼び手の既定色になる）。色の表示の整数も落ちずに作る。製品のコードがこれらを通ることも確かめる。
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEST = r'''
import AppKit
var failures = 0
func expect(_ name: String, _ ok: Bool) {
    if !ok { print("FAIL \(name)"); failures += 1 }
}
@main struct Main {
    static func main() {
        let frame = { (x: Any, y: Any, width: Any, height: Any) -> NSRect? in
            let profile: [String: Any] = ["x": x, "y": y, "w": width, "h": height]
            return profile.windowFrame(xKey: "x", yKey: "y", widthKey: "w", heightKey: "h")
        }
        expect("a saved frame", frame(100, 200, 640.5, 480) == NSRect(x: 100, y: 200, width: 640.5, height: 480))
        expect("a frame left of the main screen", frame(-300, 50, 640, 480) == NSRect(x: -300, y: 50, width: 640, height: 480))
        expect("no frame saved (zero)", frame(0, 0, 0, 0) == nil)
        for (name, values) in [("NaN x", [Double.nan, 1, 640, 480]), ("infinite y", [1, Double.infinity, 640, 480]),
                               ("infinite width", [1, 1, Double.infinity, 480]), ("NaN height", [1, 1, 640, Double.nan]),
                               ("negative width", [1, 1, -640, 480]), ("negative height", [1, 1, 640, -1]),
                               ("zero height", [1, 1, 640, 0])] {
            expect(name, frame(values[0], values[1], values[2], values[3]) == nil)
        }
        expect("a frame of text", frame("a", 1, 640, 480) == nil)

        let size = { (value: Any) in ["s": value].positiveFiniteNumberForKey("s") }
        expect("font size 12.5", size(12.5) == 12.5)
        expect("font size 0", size(0) == nil)
        expect("font size -3", size(-3) == nil)
        expect("font size inf", size(Double.infinity) == nil)
        expect("font size NaN", size(Double.nan) == nil)
        expect("font size of text", size("12") == nil)

        for (saved, expected) in [(4, 4), (1, 1), (100, 100), (101, 100), (Int.max, 100), (0, 4), (-3, 4), (Int.min, 4)] {
            expect("tab width \(saved)", validTabWidth(saved) == expected)
        }

        let color = { (string: String) in NSColor(serializedString: string) }
        if let c = color("0.250000:0.500000:1.000000:1.000000") {
            expect("a legacy color", c.redComponent == 0.25 && c.greenComponent == 0.5 && c.blueComponent == 1 && c.alphaComponent == 1)
        } else { expect("a legacy color", false) }
        for bad in ["nan:0:0:1", "0:inf:0:1", "0:0:-inf:1", "0:0:0:nan", "x:0:0:1", "0:0:0", "0:0:0:1:1", ""] {
            expect("legacy color \(bad.debugDescription) is no color", color(bad) == nil)
        }
        if let c = color("2:-1:0.5:1") {
            expect("components out of 0...1", c.redComponent == 1 && c.greenComponent == 0 && c.blueComponent == 0.5)
        } else { expect("components out of 0...1", false) }
        expect("profile color", ["c": "nan:0:0:1"].colorForKey("c") == nil)

        expect("description", NSColor(deviceRed: 1, green: 0.5, blue: 0, alpha: 1).descriptionString == "#FF8000 (R=255, G=128, B=0)")
        for bad in [CGFloat.nan, .infinity, -.infinity, 1e300, -2] {
            let text = NSColor(deviceRed: bad, green: 0, blue: 0, alpha: 1).descriptionString
            expect("description of \(bad): \(text)", text == "#000000 (R=0, G=0, B=0)" || text == "#FF0000 (R=255, G=0, B=0)")
        }
        if failures > 0 { exit(1) }
        print("OK")
    }
}
'''

# The product code goes through the checks above.
USES = {
    'Sources/Controllers/ControllerG.swift': [
        'aProfile.windowFrame(xKey: XKey, yKey: YKey, widthKey: MainWindowWidthKey, heightKey: MainWindowHeightKey)',
        'profile.positiveFiniteNumberForKey(SourceFontSizeKey) ?? 13',
        'let size = size.isFinite && size > 0 ? size : 13',
        'tabWidthTextField.integerValue = validTabWidth(aProfile.integerForKey(TabWidthKey))',
        'currentProfile[TabWidthKey] = validTabWidth(tabWidthTextField.integerValue)',
    ],
    'Sources/Editor/TeXTextView.swift': [
        'CGFloat(validTabWidth(currentProfile.integerForKey(TabWidthKey)))',
        'let tabWidth = validTabWidth(aProfile.integerForKey(TabWidthKey))',
    ],
}


def main():
    missing = [f'{path}: {use}' for path, uses in USES.items() for use in uses if use not in (ROOT / path).read_text()]
    if missing:
        print('\n'.join('FAIL: not used: ' + m for m in missing), file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory(prefix='saved-profile-values-') as directory:
        path = Path(directory)
        (path / 'Test.swift').write_text(TEST)
        sources = [str(ROOT / p) for p in ['Sources/Extensions/Foundation/NSDictionary-Extension.swift',
                                           'Sources/Extensions/AppKit/NSColor-Extension.swift']]
        subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(path / 'Test.swift'), *sources, '-o', str(path / 'test')], check=True)
        return subprocess.run([str(path / 'test')], timeout=30).returncode


if __name__ == '__main__':
    sys.exit(main())
