import Quartz

extension PDFPage {
    @objc var pageBox: PDFPageBox {
        return PDFPageBox(pdfPage: self)
    }
}
