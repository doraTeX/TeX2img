import Cocoa
import UserNotifications


extension ControllerG {
    func sendUserNotification(status: ExitStatus) {
        let title: String
        guard let body = self.currentProfile().stringForKey(OutputFileKey)?.lastPathComponent else { return }
        
        switch status {
        case .failed:
            title = NSLocalizedString("Failed", comment: "")
        case .aborted:
            title = NSLocalizedString("Aborted", comment: "")
        default:
            title = NSLocalizedString("Completed", comment: "")
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let center = UNUserNotificationCenter.current()
        // 初回の許可確認が完了してから登録する。通知音は従来どおり設定しない。
        center.requestAuthorization(options: [.sound, .badge, .alert]) { [weak self] granted, error in
            if let error = error {
                self?.appendOutputAndScroll("Notification authorization failed: \(error.localizedDescription)\n", quiet: false)
                return
            }
            guard granted else { return }
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { [weak self] error in
                if let error = error {
                    self?.appendOutputAndScroll("Notification delivery failed: \(error.localizedDescription)\n", quiet: false)
                }
            }
        }
    }
}
