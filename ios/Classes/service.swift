import Foundation
import UIKit

class Service {
    static let getInstance: Service = Service()
    let application: UIApplication = UIApplication.shared
    var delegate: ClassBDelegate!
    
    var bgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var isRunning = false
    var continousUpdates = false
    var lastValue = 0
    
    init(){
        LocalNotification.registerForLocalNotification(on: UIApplication.shared)
    }
    
    func setup(){}
    
    // prepare user notification and start service
    func start(){
        if bgTaskId != UIBackgroundTaskIdentifier.invalid {return}
        
        bgTaskId = application.beginBackgroundTask(expirationHandler: {
            /* seems not to be called ? */
            print("ios: BackgroundTask \(self.bgTaskId) expired...")
            self.start()
        })
        LocalNotification.dispatchlocalNotification(with: "Service started", body: "Background Service running.", at: Date())

        isRunning = true;
        continousUpdates = true;
        getValues()
    }
    
    // prepare user notification and stop service
    func stop() {
        if bgTaskId == UIBackgroundTaskIdentifier.invalid {return}
        LocalNotification.dispatchlocalNotification(with: "Service stopped", body: "Background Service stopped.", at: Date())
        isRunning = false
        continousUpdates = false;
        application.endBackgroundTask(bgTaskId)
        bgTaskId = UIBackgroundTaskIdentifier.invalid
          
        print("ios: BackgroundTask stopped")
    }
    
    func getValue(){
        isRunning = true;
        continousUpdates = false;
        getValues()
    }

    func getValues(){
        // background thread
        DispatchQueue.global(qos: .background).async {
            print("ios: BackgroundTask started.")
            
            // get a random 8 digits and send via AppDelegate to Flutter
            while self.isRunning {
                let value = self.getRandom()
                DispatchQueue.main.async {
                    if let delegate = self.delegate {
                        print("-->> " + String(value))
                        delegate.callback("onData", data:[value])
                    }
                }
                if !self.continousUpdates {self.isRunning = false}
                sleep(1)
            }
            self.stop()
        }
    }
 
    // generate random 8 digits
    func getRandom() -> Int {
        var number = String()
        for _ in 1...8 {  // 8 digits
           number += "\(Int.random(in: 1...9))"
        }
        return Int(number)!
    }
        
}

