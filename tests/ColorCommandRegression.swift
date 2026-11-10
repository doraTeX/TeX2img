import AppKit

// Checks the colors that the color palette turns into \color[rgb] commands. Reading redComponent of a gray,
// CMYK or named color raised an exception that the Objective-C version caught and the Swift version did not.
// Run through tests/test_color_command.py.

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}
func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.001 }

for color in [NSColor(srgbRed: 0.1, green: 0.2, blue: 0.3, alpha: 1), NSColor(calibratedRed: 0.1, green: 0.2, blue: 0.3, alpha: 1),
              NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)] {
    let c = color.rgbComponentsForColorCommand
    check(c.map { near($0.red, 0.1) && near($0.green, 0.2) && near($0.blue, 0.3) } == true, "an RGB color keeps its components: \(color)")
}
for color in [NSColor(calibratedWhite: 0.5, alpha: 1), NSColor(deviceWhite: 0.5, alpha: 1), NSColor(genericGamma22White: 0.5, alpha: 1)] {
    let c = color.rgbComponentsForColorCommand
    check(c.map { near($0.red, 0.5) && near($0.green, 0.5) && near($0.blue, 0.5) } == true, "a gray gives its level: \(color)")
}
check(NSColor(deviceCyan: 1, magenta: 0, yellow: 0, black: 0, alpha: 1).rgbComponentsForColorCommand != nil, "a CMYK color")
check(NSColor.systemRed.rgbComponentsForColorCommand.map { $0.red > 0.9 && $0.green < 0.4 } == true, "a named color")
check(NSColor(patternImage: NSImage(size: NSSize(width: 2, height: 2))).rgbComponentsForColorCommand == nil, "a pattern has no RGB")
print("Color command regression tests passed")
