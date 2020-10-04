@objc extension NSColorWell {
    func saveColor(toMutableDictionary dictionary: NSMutableDictionary) {
        dictionary[self.description] = self.color
    }

    func restoreColor(fromDictionary dictionary: NSMutableDictionary) {
        if let color = dictionary[self.description] as? NSColor {
            self.color = color
        }
    }
}
