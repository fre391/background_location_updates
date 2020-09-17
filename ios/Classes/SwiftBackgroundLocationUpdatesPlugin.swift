import Flutter
import UIKit

public class SwiftBackgroundLocationUpdatesPlugin: NSObject, FlutterPlugin {
      let service = Service()
      let locationservice = LocationService()
      var channel = FlutterMethodChannel()
      var isRunning : Bool = false
        
      public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.service", binaryMessenger: registrar.messenger())
        let instance = SwiftBackgroundLocationUpdatesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.setup(registrar: registrar)
      }

    private func setup(registrar: FlutterPluginRegistrar){
        self.channel = FlutterMethodChannel(name: "com.example.service", binaryMessenger: registrar.messenger())
        
        // configure location updates
        locationservice.setup(channel: self.channel)
        self.locationservice.setLocationManager(config: "defaults")
        service.setup(channel: self.channel)
    }
    
      public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
           switch call.method {
             case "start":
               // start the Service manually
                self.service.start();
                self.locationservice.start()
                self.callback("onMessage", data: "Service started")
                self.isRunning = true;
                self.callback("onStatus", data: [self.isRunning] )
               result(true)
             case "stop":
               // stop the Service manually
                self.service.stop()
                self.locationservice.stop()
                self.callback("onMessage", data: "Service stopped")
                self.isRunning = false;
                self.callback("onStatus", data: [self.isRunning] )
                result(true)
           case "locationSettings":
                var settings = call.arguments as! String
                settings = settings.replacingOccurrences(of: "\'", with: "\"")
                self.locationservice.setLocationManager(config: settings)
                result(true)
           case "get":
               // request new data manually
               let success = self.service.get()
               self.callback("onMessage", data: "Service value")
               result(success)
             case "initialize":
                /* not used in IOS (Andoid only)*/
                return
             case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
                return
             default:
               result(FlutterMethodNotImplemented)
           }
        }
       
       /*
       when application is in background start service automatically
       (not used in this example)
       override func applicationDidEnterBackground(_ application: UIApplication) {
           _ = self.service.start()
       }
       */
       
        /*
        callback for the Service to communicate back to Flutter
        (will be called from the Service)
        */
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
