import Quartz

@objc extension Converter {
    func cropPage(of pdfPath: String,
                  page: UInt,
                  from inputDocument: PDFDocument,
                  addMargin: Bool) -> PDFPage? {
        let index = page - 1
        let pdfPage = inputDocument.page(at: index)!
        
        let leftMargin = addMargin ? CGFloat(self.leftMargin) : 0
        let rightMargin = addMargin ? CGFloat(self.rightMargin) : 0
        let topMargin = addMargin ? CGFloat(self.topMargin): 0
        let bottomMargin = addMargin ? CGFloat(self.bottomMargin) : 0
        
        guard let bbStr = keepPageSizeFlag
            ? PDFPageBox(filePath: pdfPath, page: page).bboxString(of: pageBoxType,
                                                                   hires: false,
                                                                   addHeader: true)
                : self.bboxString(ofPdf: pdfPath, page: page, hires: false) else { return nil }
        
        if bbStr == "" {
            return nil
        }

        let bbox = bbStr.replacingOccurrences(of: "%%BoundingBox: ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .components(separatedBy: .whitespaces)
            .map{ CGFloat(Int($0)!) }
        let (bboxLx, bboxLy, bboxUx, bboxUy) = (bbox[0], bbox[1], bbox[2], bbox[3])
        
        let mediaBox = pdfPage.pageBox.mediaBoxRect()
        let (mboxLx, mboxLy, mboxUx, mboxUy) = (mediaBox.minX, mediaBox.minY, mediaBox.minX + mediaBox.width, mediaBox.minY + mediaBox.height)
        
        let rotation = pdfPage.rotation
        
        let w: CGFloat
        let h: CGFloat
        let lx: CGFloat
        let ly: CGFloat
        
        if rotation == 0 {
            w = bboxUx - bboxLx + leftMargin + rightMargin
            h = bboxUy - bboxLy + topMargin + bottomMargin
            lx = mboxLx + bboxLx - leftMargin
            ly = mboxLy + bboxLy - bottomMargin
        } else if rotation == 90 {
            w = bboxUy - bboxLy + topMargin + bottomMargin
            h = bboxUx - bboxLx + leftMargin + rightMargin
            lx = mboxUx - bboxUy - topMargin
            ly = mboxLy + bboxLx - leftMargin
        } else if rotation == 180 {
            w = bboxUx - bboxLx + leftMargin + rightMargin
            h = bboxUy - bboxLy + topMargin + bottomMargin
            lx = mboxUx - bboxUx - rightMargin
            ly = mboxUy - bboxUy - topMargin
        } else { // rotaton == 270
            w = bboxUy - bboxLy + topMargin + bottomMargin
            h = bboxUx - bboxLx + leftMargin + rightMargin
            lx = mboxLx + bboxLy - bottomMargin
            ly = mboxUy - bboxUx - rightMargin
        }
        
        guard w > 0, h > 0 else { // 消えてしまう場合は元と同じページを返す
            return pdfPage
        }
        
        let newMediaBox = NSRect(x: lx, y: ly, width: w, height: h)
        pdfPage.setBounds(newMediaBox, for: .mediaBox)
        pdfPage.setBounds(newMediaBox, for: .cropBox)
        
        return pdfPage
    }

    func generateCroppedPDF(of inputPath: String, page: UInt, to outputPath: String, addMargin: Bool) -> Bool {
        guard let inputDoc = PDFDocument(filePath: inputPath) else { return false }
        let totalPageCount = inputDoc.pageCount
        let targetPages = (page==0) ? [UInt](1...totalPageCount) : [page]
        let outputDocs = Array(0..<targetPages.count).map { _ in PDFDocument() }

        var success = true
        
        DispatchQueue.concurrentPerform(iterations: outputDocs.count) { i in
            let targetPage = targetPages[i]
            guard let croppedPage = self.cropPage(of: inputPath,
                                                  page: targetPage,
                                                  from: inputDoc,
                                                  addMargin: addMargin) else {
                success = false
                return
            }
            outputDocs[i].append(croppedPage)
        }
        
        let outputDoc = PDFDocument()
        for doc in outputDocs {
            outputDoc.append(doc.page(at: 0))
        }
        
        outputDoc.write(toFile: outputPath)
        
        return success
    }

}
