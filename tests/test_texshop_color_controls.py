"""Exercise the production color-import control installer with both nib layouts."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Sources/Controllers/ControllerG.swift").read_text()
start = source.index("    private func installTeXShopColorButtons(")
end = source.index("    @objc private func importTeXShopColors(", start)
method = source[start:end].replace("private func", "func", 1)
program = r'''
import AppKit
let LIGHTMODE_TAG = 1
let DARKMODE_TAG = 2
enum UtilityG {
    static var japanese = false
    static func isJapaneseLanguage() -> Bool { japanese }
}
class ControllerG: NSObject {
    @objc func loadDefaultColors(_ sender: NSButton) {}
    @objc func importTeXShopColors(_ sender: NSMenuItem) {}
__METHOD__
}
_ = NSApplication.shared
for japanese in [false, true] {
    UtilityG.japanese = japanese
    let controller = ControllerG()
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 452, height: 393))
    let positions: [CGFloat] = japanese ? [255, 340] : [275, 359]
    for x in positions {
        let button = NSButton(frame: NSRect(x: x, y: 5, width: 85, height: 30))
        button.action = #selector(ControllerG.loadDefaultColors(_:))
        view.addSubview(button)
    }
    // Include a hidden tab: the installer must visit all tab items, not only subviews.
    let tabs = NSTabView(frame: view.frame)
    let first = NSTabViewItem(identifier: "first")
    first.view = NSView(frame: view.frame)
    let second = NSTabViewItem(identifier: "colors")
    second.view = view
    tabs.addTabViewItem(first)
    tabs.addTabViewItem(second)
    controller.installTeXShopColorButtons(in: tabs)
    let imports = view.subviews.compactMap { $0 as? NSPopUpButton }
    precondition(imports.count == 1)
    let control = imports[0]
    precondition(control.frame.minX >= 0 && control.frame.maxX < positions[0])
    precondition(control.numberOfItems == 3)
    precondition(control.item(at: 1)?.tag == LIGHTMODE_TAG)
    precondition(control.item(at: 2)?.tag == DARKMODE_TAG)
    precondition(control.item(at: 1)?.action == #selector(ControllerG.importTeXShopColors(_:)))
}
print("Color import control tests passed (English/Japanese, hidden tabs)")
'''
with tempfile.TemporaryDirectory(prefix="texshop-color-ui-") as directory:
    path = Path(directory)
    (path / "main.swift").write_text(program.replace("__METHOD__", method))
    subprocess.run(["swiftc", str(path / "main.swift"), "-o", str(path / "test")], check=True)
    subprocess.run([str(path / "test")], check=True, timeout=20)
