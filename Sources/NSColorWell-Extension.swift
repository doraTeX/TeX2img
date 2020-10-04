@objc extension NSColorWell {
    func saveColor(to dictionary: NSMutableDictionary) {
        dictionary[self.description] = self.color
    }

    func restoreColor(from dictionary: NSMutableDictionary) {
        if let color = dictionary[self.description] as? NSColor {
            self.color = color
        }
    }
}
