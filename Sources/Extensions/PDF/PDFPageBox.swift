import Quartz

extension CGPDFBox {
    /// The five boxes of a PDF page, in the order of their numbers (the tags of the page box menu).
    static let pageBoxes: [CGPDFBox] = [.mediaBox, .cropBox, .bleedBox, .trimBox, .artBox]

    /// The box of a saved number. CGPDFBox(rawValue:) keeps any number, and a page has no box for the others;
    /// they are the MediaBox, the default.
    static func pageBox(number: Int) -> CGPDFBox {
        pageBoxes.first { Int($0.rawValue) == number } ?? .mediaBox
    }
}

class PDFPageBox: NSObject {
    let pdfPage: PDFPage
    let cgPdfPage: CGPDFPage
    
    init?(pdfPage: PDFPage) {
        guard let pageRef = pdfPage.pageRef else { return nil }
        self.pdfPage = pdfPage
        self.cgPdfPage = pageRef
        super.init()
    }
    
    convenience init?(filePath path: String, page: Int) {
        guard page > 0 else { return nil }
        let index = page - 1
        guard let pdfPage = PDFDocument(filePath: path)?.page(at: index) else { return nil }
        self.init(pdfPage: pdfPage)
    }
    
    func boxRect(_ box: CGPDFBox) -> NSRect {
        let box = CGPDFBox.pageBoxes.contains(box) ? box : .mediaBox
        return self.cgPdfPage.getBoxRect(box) as NSRect
    }
    
    var mediaBoxRect: NSRect { self.boxRect(.mediaBox) }
    var cropBoxRect: NSRect { self.boxRect(.cropBox) }
    var bleedBoxRect: NSRect { self.boxRect(.bleedBox) }
    var trimBoxRect: NSRect { self.boxRect(.trimBox) }
    var artBoxRect: NSRect { self.boxRect(.artBox) }
    
    /// The bounding box of a page box, or nil when its numbers cannot be written as integers.
    func bboxString(of box: CGPDFBox, hires: Bool, addHeader: Bool) -> String? {
        let mediaBoxRect = self.mediaBoxRect
        var rect = self.boxRect(box).intersection(mediaBoxRect) // MediaBox でクリップ
        // A box that lies outside the MediaBox has no intersection: CGRect.null, whose origin is infinite. PDFKit
        // shows such a page as empty, so the box is the empty one, 0 0 0 0, whatever the rotation of the page.
        if rect.isNull {
            rect = .zero
        } else {
            rect = rotated(rect, in: mediaBoxRect)
        }

        if hires {
            guard [rect.minX, rect.minY, rect.maxX, rect.maxY].allSatisfy(\.isFinite) else { return nil }
            return String(format: "%@%f %f %f %f\n",
                          (addHeader ? "%%HiResBoundingBox: " : ""),
                          rect.origin.x,
                          rect.origin.y,
                          rect.origin.x + rect.size.width,
                          rect.origin.y + rect.size.height)
        }
        guard let (llx, lly, urx, ury) = Self.integerBoundingBox(of: rect) else { return nil }
        return String(format: "%@%ld %ld %ld %ld\n", (addHeader ? "%%BoundingBox: " : ""), llx, lly, urx, ury)
    }

    /// The lower left corner rounded down, plus the size rounded up; nil when a number is not finite or does not
    /// fit in Int (Int(_:) and + trap on those).
    static func integerBoundingBox(of rect: CGRect) -> (Int, Int, Int, Int)? {
        guard let llx = Int(exactly: floor(rect.origin.x)),
              let lly = Int(exactly: floor(rect.origin.y)),
              let width = Int(exactly: ceil(rect.size.width)),
              let height = Int(exactly: ceil(rect.size.height)) else { return nil }
        let (urx, overflowX) = llx.addingReportingOverflow(width)
        let (ury, overflowY) = lly.addingReportingOverflow(height)
        guard !overflowX, !overflowY else { return nil }
        return (llx, lly, urx, ury)
    }

    /// A box relative to the MediaBox, turned with the page.
    private func rotated(_ box: CGRect, in mediaBoxRect: CGRect) -> CGRect {
        var rect = box
        // gs がデフォルトで -dUseMediaBox で呼ばれることに対応して，MediaBox に対する相対座標を返す
        rect.origin.x -= mediaBoxRect.origin.x
        rect.origin.y -= mediaBoxRect.origin.y

        // 回転情報の考慮
        let rotation = self.pdfPage.rotation
        if rotation == 90 {
            rect = CGRect(x: rect.origin.y,
                          y: mediaBoxRect.size.width - rect.origin.x - rect.size.width,
                          width: rect.size.height,
                          height: rect.size.width)
        }
        if (rotation == 180) {
            rect = CGRect(x: mediaBoxRect.size.width - rect.origin.x - rect.size.width,
                          y: mediaBoxRect.size.height - rect.origin.y - rect.size.height,
                          width: rect.size.width,
                          height: rect.size.height)
        }
        if (rotation == 270) {
            rect = CGRect(x: mediaBoxRect.size.height - rect.origin.y - rect.size.height,
                          y: rect.origin.x,
                          width: rect.size.height,
                          height: rect.size.width)
        }
        
        return rect
    }
}
