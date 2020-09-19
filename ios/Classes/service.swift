import Foundation
import UIKit

class Service {
    static let getInstance: Service = Service()
    let application: UIApplication = UIApplication.shared
    var delegate: ClassBDelegate!
    
    var bgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var finished = true;
    var lastValue = 0
    
    init(){
        LocalNotification.registerForLocalNotification(on: UIApplication.shared)
    }
    
    func setup(){}
    
    // prepare user notification and start service
    func start(){
        if self.bgTaskId != UIBackgroundTaskIdentifier.invalid {return}
        
        self.bgTaskId = self.application.beginBackgroundTask(expirationHandler: {
            /* seems not to be called ? */
            print("ios: BackgroundTask \(self.bgTaskId) expired...")
        })
        LocalNotification.dispatchlocalNotification(with: "Service started", body: "Background Service running.", at: Date())

        self.finished = false;
              
        // background thread
        DispatchQueue.global(qos: .background).async {
            print("ios: BackgroundTask started.")
            
            // get a random 8 digits and send via AppDelegate to Flutter
            while !self.finished {
                self.get()
                sleep(1)
                // when done, set finished to true (not used here)
                // If that doesn't happen in time, the expiration handler will do it for us,
                // but it doesnt :-) (refer above)
                
                /* room for improovement */
            }
        }

    }
    
    // prepare user notification and stop service
    func stop() {

        if self.bgTaskId == UIBackgroundTaskIdentifier.invalid {return}
        LocalNotification.dispatchlocalNotification(with: "Service stopped", body: "Background Service stopped.", at: Date())
        
        self.finished = true
              
        self.application.endBackgroundTask(self.bgTaskId)
        self.bgTaskId = UIBackgroundTaskIdentifier.invalid
          
        print("ios: BackgroundTask stopped")
    }

    // get a random 8 digit manually and send via AppDelegate to Flutter
    func get() -> Bool {
        let value = self.getValue()
        self.onData(value: value)
        return true
    }
 
    // generate random 8 digits
    func getValue() -> Int {
        var number = String()
        for _ in 1...8 {  // 8 digits
           number += "\(Int.random(in: 1...9))"
        }
        return Int(number)!
    }
    
    // send data to Flutter via AppDelegate
    func onData(value: Int){
        DispatchQueue.main.async {
            if let delegate = self.delegate {
                delegate.callback("onData", data:[value])
            }
            //self.callback("onData", data: [value])
        }
    }
    
}

