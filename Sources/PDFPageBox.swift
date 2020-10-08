import Quartz

class PDFPageBox: NSObject {
    let pdfPage: PDFPage
    let cgPdfPage: CGPDFPage
    
    init(pdfPage: PDFPage) {
        self.pdfPage = pdfPage
        self.cgPdfPage = pdfPage.pageRef!
        super.init()
    }
    
    @objc convenience init?(filePath path: String, page: UInt) {
        guard page > 0 else { return nil }
        let index = page - 1
        guard let pdfPage = PDFDocument(filePath: path)?.page(at: index) else { return nil }
        self.init(pdfPage: pdfPage)
    }
    
    func boxRect(_ box: CGPDFBox) -> NSRect {
        return self.cgPdfPage.getBoxRect(box) as NSRect
    }
    
    var mediaBoxRect: NSRect { self.boxRect(.mediaBox) }
    var cropBoxRect: NSRect { self.boxRect(.cropBox) }
    var bleedBoxRect: NSRect { self.boxRect(.bleedBox) }
    var trimBoxRect: NSRect { self.boxRect(.trimBox) }
    var artBoxRect: NSRect { self.boxRect(.artBox) }
    
    @objc func bboxString(of box: CGPDFBox, hires: Bool, addHeader: Bool) -> String {
        let mediaBoxRect = self.mediaBoxRect
        var rect = self.boxRect(box).intersection(mediaBoxRect) // MediaBox でクリップ
        
        // gs がデフォルトで -dUseMediaBox で呼ばれることに対応して，MediaBox に対する相対座標を返す
        rect.origin.x -= mediaBoxRect.origin.x
        rect.origin.y -= mediaBoxRect.origin.y
        
        let result: String
        
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
        
        if hires {
            result = String(format: "%@%f %f %f %f\n",
                            (addHeader ? "%%HiResBoundingBox: " : ""),
                            rect.origin.x,
                            rect.origin.y,
                            rect.origin.x + rect.size.width,
                            rect.origin.y + rect.size.height)
        } else {
            result = String(format: "%@%ld %ld %ld %ld\n",
                            (addHeader ? "%%BoundingBox: " : ""),
                            Int(floor(rect.origin.x)),
                            Int(floor(rect.origin.y)),
                            Int(floor(rect.origin.x)) + Int(ceil(rect.size.width)),
                            Int(floor(rect.origin.y)) + Int(ceil(rect.size.height)))
        }
        
        return result
    }
}
