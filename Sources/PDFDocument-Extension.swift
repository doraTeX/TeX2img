import Quartz

extension PDFDocument {
    @objc convenience init?(filePath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }

    @objc convenience init?(merging paths: [String]) {
        guard let firstPath = paths.first else { return nil }
        self.init(filePath: firstPath)

        var pageCount = self.pageCount
        
        for path in paths {
            guard let insertedDoc = PDFDocument(filePath: path) else { return nil }
            for j in 0..<insertedDoc.pageCount {
                if let page = insertedDoc.page(at: j) {
                    self.insert(page, at: pageCount)
                }
                pageCount += 1
            }
        }
        
    }

    func append(_ page: PDFPage) {
        insert(page, at: self.pageCount)
    }

    // 1ページのみの PDF の MediaBox の背景を指定された色で塗りつぶす（複数ページPDFは未対応）。
    // 日本語の埋め込みテキストは壊れてしまう。
    @objc class func fillBackground(of path: String, with fillColor: NSColor) {
        guard let doc = PDFDocument(filePath: path) else { return }
        let pageCount = doc.pageCount
        let fillColorRef = fillColor.cgColor

        for i in 0..<pageCount {
            guard let pdfPageRef = doc.page(at: i)?.pageRef else { return }
            var mediaBoxRect = pdfPageRef.getBoxRect(.mediaBox)

            guard let contextRef = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &mediaBoxRect, nil) else { return }

            contextRef.beginPDFPage(nil)

            contextRef.saveGState()

            contextRef.setFillColor(fillColorRef)
            let drawRect = CGRect(x: mediaBoxRect.origin.x - 1,
                                  y: mediaBoxRect.origin.y - 1,
                                  width: mediaBoxRect.size.width + 2,
                                  height: mediaBoxRect.size.height + 2)
            contextRef.fill(drawRect)
            contextRef.drawPDFPage(pdfPageRef)

            contextRef.restoreGState()

            contextRef.endPDFPage()
        }
    }

}
