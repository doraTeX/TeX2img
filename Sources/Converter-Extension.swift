import Quartz

extension Converter {
    
    /// EPSのDataの中から BoundingBox または HiresBoundingBox の値を探し，その範囲と値を返す
    /// - Parameters:
    ///   - data: EPSを読み込んだData
    ///   - hires: HiResBoundingBox の方を読むか否か
    /// - Returns: 指定されたBBoxの範囲と値
    func bboxOf(data: Data, hires: Bool) -> (range: Range<Data.Index>, content: String)? {
        let header = "%%" + (hires ? "HiRes" : "") + "BoundingBox: "
        guard let returnCharData = "\n".data(using: .utf8),
              let headerData = header.data(using: .utf8),
              let headerRange = data.range(of: headerData) else { return nil }
        
        let searchRange = headerRange.upperBound..<data.endIndex
        guard let contentEndIndex = data.range(of: returnCharData, options: [], in: searchRange)?.startIndex else { return nil }
        let contentRange = headerRange.endIndex..<contentEndIndex
        guard let content = String(data: data.subdata(in: contentRange), encoding: .utf8) else { return nil }
        
        return (range: contentRange, content: content)
    }
    
    
    /// EPSの BoundingBox および HiResBoundingBox の内容を，指定された内容に置換する
    /// - Parameters:
    ///   - epsPath: EPSのパス
    ///   - boundingBox: 新しいBoundingBoxの内容
    ///   - hiresBoundingBox: 新しいHiResBoundingBoxの内容
    @objc func replaceBBoxOf(epsPath: String, boundingBox: String, hiresBoundingBox: String) {
        guard var epsData = Data(filePath: epsPath),
              let bboxData = boundingBox.data(using: .utf8),
              let hiresBboxData = hiresBoundingBox.data(using: .utf8) else { return }
        
        if let bbArea = bboxOf(data: epsData, hires: false) {
            epsData.replaceSubrange(bbArea.range, with: bboxData)
        }

        if let hiresBbArea = bboxOf(data: epsData, hires: true) {
            epsData.replaceSubrange(hiresBbArea.range, with: hiresBboxData)
        }

        guard epsData.write(toFile: epsPath) else { return }
    }
    
    
    @objc func enlargeBoundingBox(of epsPath: String) {
        
        enum BoundingBoxType {
            case boundingBox
            case hiresBoundingBox
            
            var regexPattern: String {
                switch self {
                case .boundingBox:
                    return #"^(\-?\d+) (\-?\d+) (\-?\d+) (\-?\d+)$"#
                case .hiresBoundingBox:
                    return #"^(\-?[\d\.]+) (\-?[\d\.]+) (\-?[\d\.]+) (\-?[\d\.]+)$"#
                }
            }
            
            var regex: NSRegularExpression {
                return try! NSRegularExpression(pattern: self.regexPattern, options: [])
            }
            
            func checkingResultOf(content: String) -> NSTextCheckingResult? {
                let range = NSRange(location: 0, length: content.count)
                return self.regex.firstMatch(in: content, options: [], range: range)
            }
        }
        
        guard var epsData = Data(filePath: epsPath) else { return }

        if let bbArea = bboxOf(data: epsData, hires: false),
           let match = BoundingBoxType.boundingBox.checkingResultOf(content: bbArea.content) {
            
            let matchingAt = { Int((bbArea.content as NSString).substring(with: match.range(at: $0)))! }

            let llx = matchingAt(1) - leftMargin
            let lly = matchingAt(2) - bottomMargin
            let urx = matchingAt(3) + rightMargin
            let ury = matchingAt(4) + topMargin
            let newContent = "\(llx) \(lly) \(urx) \(ury)"
            guard let newData = newContent.data(using: .utf8) else { return }

            epsData.replaceSubrange(bbArea.range, with: newData)
        }

        if let hiresBbArea = bboxOf(data: epsData, hires: true),
           let match = BoundingBoxType.hiresBoundingBox.checkingResultOf(content: hiresBbArea.content) {
            
            let matchingAt = { Double((hiresBbArea.content as NSString).substring(with: match.range(at: $0)))! }

            let llx = matchingAt(1) - Double(leftMargin)
            let lly = matchingAt(2) - Double(bottomMargin)
            let urx = matchingAt(3) + Double(rightMargin)
            let ury = matchingAt(4) + Double(topMargin)
            let newContent = "\(llx) \(lly) \(urx) \(ury)"
            guard let newData = newContent.data(using: .utf8) else { return }

            epsData.replaceSubrange(hiresBbArea.range, with: newData)
        }

        guard epsData.write(toFile: epsPath) else { return }
    }
    
    /// PDFの特定の1ページの余白をクロップする
    /// - Parameters:
    ///   - pdfPath: 入力PDFパス
    ///   - page: ページ番号(1-index)
    ///   - inputDocument: 入力PDFを読み込んだPDFDocumentオブジェクト
    ///   - addMargin: 余白付与するか
    /// - Returns: クロップされたPDFPageオブジェクト
    func cropPage(of pdfPath: String,
                  page: UInt,
                  from inputDocument: PDFDocument,
                  addMargin: Bool) -> PDFPage? {
        let index = page - 1
        guard let pdfPage = inputDocument.page(at: index) else { return nil }
        
        let leftMargin = addMargin ? CGFloat(self.leftMargin) : 0
        let rightMargin = addMargin ? CGFloat(self.rightMargin) : 0
        let topMargin = addMargin ? CGFloat(self.topMargin): 0
        let bottomMargin = addMargin ? CGFloat(self.bottomMargin) : 0
        
        guard let bbStr = keepPageSizeFlag
                ? PDFPageBox(filePath: pdfPath, page: page)?.bboxString(of: pageBoxType,
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
        
        let mediaBox = pdfPage.pageBox.mediaBoxRect
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

    
    /// PDFの全ページ余白をクロップしたPDFを生成する
    /// - Parameters:
    ///   - inputPath: 入力PDFパス
    ///   - page: 特定のページ番号(1-index)，または0を指定した場合は全ページ対象
    ///   - outputPath: 出力PDFパス
    ///   - addMargin: 余白付与するか
    /// - Returns: 成功・失敗
    @objc func generateCroppedPDF(of inputPath: String, page: UInt, to outputPath: String, addMargin: Bool) -> Bool {
        guard let inputDoc = PDFDocument(filePath: inputPath) else { return false }
        let totalPageCount = inputDoc.pageCount
        let targetPages = (page==0) ? [UInt](1...totalPageCount) : [page]
        let outputDocs = (0..<targetPages.count).map { _ in PDFDocument() }

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
        
        PDFDocument(merging: outputDocs).write(toFile: outputPath)
        
        return success
    }

}
