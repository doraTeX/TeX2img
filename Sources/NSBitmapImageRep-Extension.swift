import Cocoa

extension NSBitmapImageRep {
    @objc func representation(usingType type: CFString, usingDPI dpi: Int) -> Data? {
        let prop : [String:NSNumber] = [
            kCGImageDestinationLossyCompressionQuality as String: 1.0,
            kCGImagePropertyDPIWidth as String: NSNumber(value: dpi),
            kCGImagePropertyDPIHeight as String: NSNumber(value: dpi)
        ]

        let data = NSMutableData() as CFMutableData
        guard
              let destination = CGImageDestinationCreateWithData(data, type, 1, nil),
              let cgImage = self.cgImage else { return nil }

        CGImageDestinationAddImage(destination, cgImage, prop as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data?
    }
}

