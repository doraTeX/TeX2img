import Cocoa
import UserNotifications

@objc class UserNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, NSUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

@available(macOS 10.14, *)
extension UserNotificationDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .alert, .badge])
    }
}
