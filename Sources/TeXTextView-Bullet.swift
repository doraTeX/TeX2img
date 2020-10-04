// Control bullets (based on TeXShop, translated into Swift by Yusuke Terada)

fileprivate let placeholderString = "\u{2022}" // "•"
fileprivate let startCommentString = "\u{2022}\u{2039}" // "•‹"
fileprivate let endCommentString = "\u{203A}" // "›"

@objc extension TeXTextView {
    @IBAction func doNextBullet(_ sender: Any) {  // modified by (HS)
        let text = self.string as NSString
        var tempRange = self.selectedRange
        tempRange.location += tempRange.length // move the range to after the selection (a la Find) to avoid re-finding (HS)
        //set up a search range from here to eof
        let forwardRange = NSRange(location: tempRange.location, length: text.length - tempRange.location)
        var markerRange = text.range(of: placeholderString, options: .literal, range: forwardRange)

        //if marker found - set commentRange there and look for end of comment
        if markerRange.location != NSNotFound {
            // marker found
            var commentRange = NSRange(location: markerRange.location, length: text.length - markerRange.location)
            commentRange = text.range(of: startCommentString, options: .literal, range: commentRange)

            if (commentRange.location != NSNotFound) && (commentRange.location == markerRange.location) {
                // found comment start right after marker --- there is a comment
                commentRange.location = markerRange.location
                commentRange.length = text.length - markerRange.location
                commentRange = text.range(of: endCommentString, options: .literal, range: commentRange)

                if commentRange.location != NSNotFound {
                    markerRange.length = commentRange.location - markerRange.location + commentRange.length
                }
            }

            self.selectedRange = markerRange
            self.scrollRangeToVisible(markerRange)
        
        } else {
            NSSound.beep()
        }
    }
    
    
    @IBAction func doPreviousBullet(_ sender: Any) { // modified by (HS)
        let text = self.string as NSString
        let tempRange = self.selectedRange
        //set up a search range from string start to beginning of selection
        let backwardRange = NSRange(location: 0, length: tempRange.location)
        var markerRange = text.range(of: placeholderString, options: .backwards, range: backwardRange)

        //if marker found - set commentRange there and look for end of comment
        if markerRange.location != NSNotFound { // marker found
            var commentRange = NSRange(location: markerRange.location, length: text.length - markerRange.location)
            commentRange = text.range(of: startCommentString, options: .literal, range: commentRange)

            if (commentRange.location != NSNotFound) && (commentRange.location == markerRange.location) {
                // found comment start right after marker --- there is a comment
                commentRange.location = markerRange.location
                commentRange.length = text.length - markerRange.location
                commentRange = text.range(of: endCommentString, options: .literal, range: commentRange)

                if commentRange.location != NSNotFound {
                    markerRange.length = commentRange.location - markerRange.location + commentRange.length
                }
            }

            self.selectedRange = markerRange
            self.scrollRangeToVisible(markerRange)

        } else {
            NSSound.beep()
        }
    }


    @IBAction func doNextBulletAndDelete(_ sender: Any) { // modified by (HS)
        let text = self.string as NSString
        var tempRange = self.selectedRange
        tempRange.location += tempRange.length // move the range to after the selection (a la Find) to avoid re-finding (HS)
        //set up a search range from here to eof
        let forwardRange = NSRange(location: tempRange.location, length: text.length - tempRange.location)
        var markerRange = text.range(of: placeholderString, options: .literal, range: forwardRange)
        //if marker found - set commentRange there and look for end of comment
        if markerRange.location != NSNotFound { // marker found
            var commentRange = NSRange(location: markerRange.location, length: text.length - markerRange.location)
            commentRange = text.range(of: startCommentString, options: .literal, range: commentRange)

            if (commentRange.location != NSNotFound) && (commentRange.location == markerRange.location) {
                // found comment start right after marker --- there is a comment
                commentRange.location = markerRange.location
                commentRange.length = text.length - markerRange.location
                commentRange = text.range(of: endCommentString, options: .literal, range: commentRange)

                if commentRange.location != NSNotFound {
                    markerRange.length = commentRange.location - markerRange.location + commentRange.length
                }
            }

            // delete bullet (marker)
            tempRange.location = markerRange.location
            tempRange.length = (placeholderString as NSString).length
            markerRange.length -= tempRange.length // deleting the bullet so selection is shorter
            self.replaceCharacters(in: tempRange, with: "")

            // end delete bullet (marker)
            self.selectedRange = markerRange
            self.scrollRangeToVisible(markerRange)

        } else {
            NSSound.beep()
        }
    }

    
    @IBAction func doPreviousBulletAndDelete(_ sender: Any) { // modified by (HS)
        let text = self.string as NSString
        var tempRange = self.selectedRange
        //set up a search range from string start to beginning of selection
        let backwardRange = NSRange(location: 0, length: tempRange.location)
        var markerRange = text.range(of: placeholderString, options: .backwards, range:backwardRange)

        //if marker found - set commentRange there and look for end of comment
        if markerRange.location != NSNotFound { // marker found
            var commentRange = NSRange(location: markerRange.location, length: text.length - markerRange.location)
            commentRange = text.range(of: startCommentString, options: .literal, range: commentRange)

            if (commentRange.location != NSNotFound) && (commentRange.location == markerRange.location) {
                // found comment start right after marker --- there is a comment
                var commentRange = NSRange(location: markerRange.location, length: text.length - markerRange.location)
                commentRange = text.range(of: endCommentString, options: .literal, range: commentRange)

                if commentRange.location != NSNotFound {
                    markerRange.length = commentRange.location - markerRange.location + commentRange.length
                }
            }
            
            // delete bullet (marker)
            tempRange.location = markerRange.location
            tempRange.length = (placeholderString as NSString).length
            markerRange.length -= tempRange.length // deleting the bullet so selection is shorter
            self.replaceCharacters(in: tempRange, with: "")
            
            // end delete bullet (marker)
            self.selectedRange = markerRange
            self.scrollRangeToVisible(markerRange)

        } else {
            NSSound.beep()
        }
    }

    
    @IBAction func placeBullet(_ sender: Any) { // modified by (HS) to be a simple insertion (replacing the selection)
        var myRange = self.selectedRange
        self.replaceCharacters(in: myRange, with: placeholderString) //" •\n" puts • on previous line
        myRange.location += (placeholderString as NSString).length //= end+2;//start puts • on previous line
        myRange.length = 0
        self.selectedRange = myRange
    }

    
    @IBAction func placeComment(_ sender: Any) { // by (HS) to be a simple insertion (replacing the selection)
        var myRange = self.selectedRange
        self.replaceCharacters(in: myRange, with: startCommentString) //" •\n" puts • on previous line
        myRange.location += (startCommentString as NSString).length //= end+2;//start puts • on previous line
        myRange.length = 0
        self.replaceCharacters(in: myRange, with: endCommentString)
        self.selectedRange = myRange
    }

}

