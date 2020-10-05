import Quartz

extension PDFDocument {
    @objc convenience init?(filePath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }

    @objc convenience init?(merging paths: [String]) {
        let docs = paths.map { PDFDocument(filePath: $0) }
        if docs.contains(nil) {
            return nil
        }

        self.init()
        self.append(docs.compactMap{$0})
    }

    convenience init(merging documents: [PDFDocument]) {
        self.init()
        self.append(documents)
    }

    var pages: [PDFPage] {
        return (0..<self.pageCount).compactMap{ self.page(at: $0) }
    }
    
    func append(_ page: PDFPage) {
        self.insert(page, at: self.pageCount)
    }

    func append(_ document: PDFDocument) {
        document.pages.forEach { self.append($0) }
    }

    func append(_ documents: [PDFDocument]) {
        documents.forEach { self.append($0) }
    }
    
    // 1ページのみの PDF の MediaBox の背景を指定された色で塗りつぶす（複数ページPDFは未対応）。
    // 日本語の埋め込みテキストは壊れてしまう。
    @objc class func fillBackground(of path: String, with fillColor: NSColor) {
        guard let doc = PDFDocument(filePath: path) else { return }
        let fillColorRef = fillColor.cgColor

        for page in doc.pages {
            guard let pdfPageRef = page.pageRef else { return }
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
