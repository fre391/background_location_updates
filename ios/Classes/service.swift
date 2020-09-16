import Foundation
import UIKit

class Service {
    static let getInstance: Service = Service()
    let application: UIApplication = UIApplication.shared
    var channel = FlutterMethodChannel()
        
    var bgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var finished = true;
    
    init(){
        LocalNotification.registerForLocalNotification(on: UIApplication.shared)
    }
    
    func setup(channel: FlutterMethodChannel){
        self.channel = channel
    }
    
    // prepare user notification and start service
    func start() -> Bool{
        if self.bgTaskId != UIBackgroundTaskIdentifier.invalid {return false}
        
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
                let value = self.getValue()
                self.onData(value: value)
                sleep(1)
                // when done, set finished to true (not used here)
                // If that doesn't happen in time, the expiration handler will do it for us,
                // but it doesnt :-) (refer above)
                
                /* room for improovement */
            }
        }
 
        return true
    }
    
    // prepare user notification and stop service
    func stop() -> Bool{

        if self.bgTaskId == UIBackgroundTaskIdentifier.invalid {return false}
        LocalNotification.dispatchlocalNotification(with: "Service stopped", body: "Background Service stopped.", at: Date())
        
        self.finished = true
              
        self.application.endBackgroundTask(self.bgTaskId)
        self.bgTaskId = UIBackgroundTaskIdentifier.invalid
          
        print("ios: BackgroundTask stopped")
        return true
    }

    // get a random 8 digit manually and send via AppDelegate to Flutter
    func get() -> Bool {
        DispatchQueue.global(qos: .background).async {
            let value = self.getValue()
            self.onData(value: value)
        }
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
            self.callback("onData", data: [value])
        }
    }
    
        func callback<T: Encodable>(_ method:String, data: T) {
            let val = self.toJson(data)
            self.channel.invokeMethod(method, arguments: String(val))
        }
    
       func toJson<T: Encodable>(_ data: T)->String {
           if let json = try? JSONEncoder().encode(data) {
               if let str = String(data: json, encoding: .utf8) {
                   return str
               }
           }
           return ""
       }
}

