import Quartz

extension PDFPage {
    var pageBox: PDFPageBox? {
        PDFPageBox(pdfPage: self)
    }
}
