"""実際の保存形式変更メソッドを、アクセサリが別ウインドウにある条件で検証。"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'Sources/Controllers/ControllerG.swift').read_text()
start = source.index('    @IBAction private func extensionPopUpButtonInSavePanelChanged(')
end = source.index('    @IBAction func toggleMenuItem(', start)
method = source[start:end].replace('@IBAction private func', 'func', 1)
code = r'''
import AppKit
import UniformTypeIdentifiers
class Harness {
    var outputSavePanel: NSSavePanel?
__METHOD__
}
@main struct Test {
    static func main() {
        _ = NSApplication.shared
        let panel = NSSavePanel()
        let accessoryWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 150, height: 30))
        let formats = ["EPS", "PDF", "SVG", "SVGZ", "JPG", "PNG", "GIF", "TIFF", "BMP"]
        popup.addItems(withTitles: formats)
        accessoryWindow.contentView?.addSubview(popup)
        precondition(popup.window !== panel)
        let harness = Harness()
        harness.outputSavePanel = panel
        let originalTypes = Set(formats.compactMap { UTType(filenameExtension: $0.lowercased()) })
        panel.allowedContentTypes = Array(originalTypes)
        panel.nameFieldStringValue = "日本語 test.eps"
        for format in formats.reversed() {
            popup.selectItem(withTitle: format)
            harness.extensionPopUpButtonInSavePanelChanged(popup)
            precondition(panel.nameFieldStringValue == "日本語 test.\(format.lowercased())")
            precondition(panel.allowedContentTypes.first == UTType(filenameExtension: format.lowercased()))
            precondition(Set(panel.allowedContentTypes) == originalTypes)
        }
        print("別ウインドウのアクセサリから保存形式9種類を変更: 成功")
    }
}
'''.replace('__METHOD__', method)
with tempfile.TemporaryDirectory(prefix='tex2img-panel-') as directory:
    path = Path(directory)
    (path / 'Test.swift').write_text(code)
    subprocess.run(['swiftc', '-parse-as-library', str(path / 'Test.swift'),
                    str(ROOT / 'Sources/Extensions/Foundation/String-Extension.swift'),
                    str(ROOT / 'Sources/NSString/NSString-Extension.swift'),
                    '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True, timeout=20)
