import UIKit
import UserNotifications

class LocalNotification: NSObject, UNUserNotificationCenterDelegate {

    class func registerForLocalNotification(on application:UIApplication) {
        if (UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:)))) {
            let notificationCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
            notificationCategory.identifier = "NOTIFICATION_CATEGORY"

            //registerting for the notification.
            application.registerUserNotificationSettings(UIUserNotificationSettings(types:[.sound, .alert, .badge], categories: nil))
        }
    }

    class func dispatchlocalNotification(with title: String, body: String, userInfo: [AnyHashable: Any]? = nil, at date:Date) {

        if #available(iOS 10.0, *) {

            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.categoryIdentifier = "Fechou"

            if let info = userInfo {
                content.userInfo = info
            }

            content.sound = UNNotificationSound.default

            let comp = Calendar.current.dateComponents([.hour, .minute], from: date)

            let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            center.add(request)

        } else {

            let notification = UILocalNotification()
            notification.fireDate = date
            if #available(iOS 8.2, *) {
                notification.alertTitle = title
            } else {
                // Fallback on earlier versions
            }
            notification.alertBody = body

            if let info = userInfo {
                notification.userInfo = info
            }

            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
}
