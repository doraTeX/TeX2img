import AppKit
import Foundation

private let movedRowsPasteboardType = NSPasteboard.PasteboardType("TeX2imgMovedRowsType")
private let profileNamesKey = "profileNames"
private let profilesKey = "profiles"

@objc(ProfileController)
class ProfileController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private var profiles = [NSDictionary]()
    private var profileNames = [String]()

    @IBOutlet private var profilesWindow: NSWindow!
    @IBOutlet private var profilesTableView: NSTableView!
    @IBOutlet private var saveAsTextField: NSTextField!
    @IBOutlet private var controllerG: ControllerG!

    @objc func profileForName(_ profileName: String) -> NSMutableDictionary? {
        guard let targetIndex = profileNames.firstIndex(of: profileName) else { return nil }
        return NSMutableDictionary(dictionary: profiles[targetIndex])
    }

    @objc func loadProfilesFromPlist() {
        let defaults = UserDefaults.standard
        if let names = defaults.array(forKey: profileNamesKey) as? [String] {
            profileNames = names
        }
        if let storedProfiles = defaults.array(forKey: profilesKey) as? [NSDictionary] {
            profiles = storedProfiles
        }
    }

    @objc func initProfiles() {
        profileNames = []
        profiles = []
    }

    @objc func removeProfileForName(_ profileName: String) {
        guard let targetIndex = profileNames.firstIndex(of: profileName) else { return }
        profileNames.remove(at: targetIndex)
        profiles.remove(at: targetIndex)
    }

    @objc func updateProfile(_ aProfile: NSDictionary, forName profileName: String) {
        if let targetIndex = profileNames.firstIndex(of: profileName) {
            profileNames[targetIndex] = profileName
            profiles[targetIndex] = aProfile
        } else {
            profileNames.append(profileName)
            profiles.append(aProfile)
        }
    }

    @objc func saveProfiles() {
        let defaults = UserDefaults.standard
        defaults.set(profileNames, forKey: profileNamesKey)
        defaults.set(profiles, forKey: profilesKey)
        defaults.synchronize()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        profileNames.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row rowIndex: Int) -> Any? {
        profileNames[rowIndex]
    }

    @IBAction func addProfile(_ sender: Any) {
        let newProfileName = saveAsTextField.stringValue

        if newProfileName.isEmpty {
            NSSound.beep()
            UtilityG.runErrorPanel(message: NSLocalizedString("emptyProfileNameErrMsg", comment: ""))
            return
        }

        if profileNames.contains(newProfileName) {
            if UtilityG.runConfirmPanel(message: NSLocalizedString("profileOverwriteMsg", comment: "")) {
                updateProfile(controllerG.currentProfile(), forName: newProfileName)
                saveAsTextField.stringValue = ""
            } else {
                profilesWindow.makeFirstResponder(saveAsTextField)
            }
        } else {
            updateProfile(controllerG.currentProfile(), forName: newProfileName)
            saveAsTextField.stringValue = ""
            profilesWindow.makeFirstResponder(saveAsTextField)
        }
        profilesTableView.reloadData()
    }

    @IBAction func loadProfile(_ sender: Any) {
        let selectedIndex = profilesTableView.selectedRow
        guard selectedIndex != -1 else { return }

        controllerG.adoptProfile(profiles[selectedIndex] as? [String: Any] ?? [:])
        profilesWindow.close()
    }

    @IBAction func removeProfile(_ sender: Any) {
        let selectedIndex = profilesTableView.selectedRow
        guard selectedIndex != -1 else { return }

        profileNames.remove(at: selectedIndex)
        profiles.remove(at: selectedIndex)
        profilesTableView.reloadData()
    }

    override func awakeFromNib() {
        profilesTableView.target = self
        profilesTableView.action = #selector(setSelectedProfileName(_:))
        profilesTableView.doubleAction = #selector(loadProfile(_:))

        profilesTableView.setDraggingSourceOperationMask(.move, forLocal: true)
        profilesTableView.registerForDraggedTypes([movedRowsPasteboardType])
    }

    @IBAction func setSelectedProfileName(_ sender: Any) {
        let selectedIndex = profilesTableView.selectedRow
        guard selectedIndex != -1 else { return }

        saveAsTextField.stringValue = profileNames[selectedIndex]
    }

    @objc func showProfileWindow() {
        profilesWindow.makeKeyAndOrderFront(nil)
    }

    func tableView(_ tableView: NSTableView,
                   writeRowsWith rowIndexes: IndexSet,
                   to pboard: NSPasteboard) -> Bool {
        pboard.declareTypes([movedRowsPasteboardType], owner: self)
        if let rowIndexesArchive = try? NSKeyedArchiver.archivedData(withRootObject: rowIndexes,
                                                                     requiringSecureCoding: false) {
            pboard.setData(rowIndexesArchive, forType: movedRowsPasteboardType)
        }
        return true
    }

    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        tableView.setDropRow(row, dropOperation: .above)

        if info.draggingSource as? NSTableView === profilesTableView {
            return .move
        }
        return []
    }

    private func moveObjects<T>(in array: inout [T],
                                fromIndexes: IndexSet,
                                toIndex insertIndex: Int) -> IndexSet {
        let adjustedInsertIndex = insertIndex - (fromIndexes as NSIndexSet).countOfIndexes(in: NSRange(location: 0, length: insertIndex))
        let objectsToMove = fromIndexes.map { array[$0] }
        for index in fromIndexes.reversed() {
            array.remove(at: index)
        }
        for (offset, object) in objectsToMove.enumerated() {
            array.insert(object, at: adjustedInsertIndex + offset)
        }
        return IndexSet(integersIn: adjustedInsertIndex..<(adjustedInsertIndex + objectsToMove.count))
    }

    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row insertionRow: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        var row = insertionRow
        if row < 0 {
            row = 0
        }

        if info.draggingSource as? NSTableView === profilesTableView {
            let optionKeyPressed = NSApp.currentEvent?.modifierFlags.contains(.option) == true
            if !optionKeyPressed,
               let rowsData = info.draggingPasteboard.data(forType: movedRowsPasteboardType),
               let indexSet = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rowsData) as? IndexSet {
                let newIndexes = moveObjects(in: &profileNames, fromIndexes: indexSet, toIndex: row)
                _ = moveObjects(in: &profiles, fromIndexes: indexSet, toIndex: row)
                tableView.selectRowIndexes(newIndexes, byExtendingSelection: false)
                tableView.reloadData()
                return true
            }
        }

        return false
    }
}