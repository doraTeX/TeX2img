import Cocoa
import UserNotifications


extension ControllerG {
    @objc func sendUserNotification(status: ExitStatus) {
        let title: String
        guard let body = (self.currentProfile()["outputFile"] as? NSString)?.lastPathComponent else { return }
        
        switch status {
        case .failed:
            title = NSLocalizedString("Failed", comment: "")
        case .aborted:
            title = NSLocalizedString("Aborted", comment: "")
        default:
            title = NSLocalizedString("Completed", comment: "")
        }
        
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert]) { (_, _) in }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        } else {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = body
            
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
}
