import Quartz

extension PDFPage {
    var pageBox: PDFPageBox {
        return PDFPageBox(pdfPage: self)
    }
}
