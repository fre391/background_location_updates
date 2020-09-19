import Flutter
import UIKit


protocol ClassBDelegate {
    func callback<T: Encodable>(_ method:String, data: T)
}

public class SwiftBackgroundLocationUpdatesPlugin: NSObject, FlutterPlugin, ClassBDelegate {
      let service = Service()
      let locationservice = LocationService()
      var channel = FlutterMethodChannel()
      var isRunning : Bool = false
        
    
      public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "de.openvfr.background_location_updates", binaryMessenger: registrar.messenger())
        let instance = SwiftBackgroundLocationUpdatesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.setup(registrar: registrar)
      }

    private func setup(registrar: FlutterPluginRegistrar){
        channel = FlutterMethodChannel(name: "de.openvfr.background_location_updates", binaryMessenger: registrar.messenger())
        
        // configure location updates
        locationservice.setup(config: "defaults")
        locationservice.delegate = self
        service.setup()
        service.delegate = self
    }
    
      public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
           switch call.method {
             case "start":
               // start the Service manually
                service.start();
                locationservice.start()
                isRunning = true;
                callback("onStatus", data: isRunning)
                result(isRunning)
             case "stop":
               // stop the Service manually
                service.stop()
                locationservice.stop()
                isRunning = false;
                callback("onStatus", data: isRunning)
                result(isRunning)
           case "locationSettings":
                var settings = call.arguments as! String
                settings = settings.replacingOccurrences(of: "\'", with: "\"")
                locationservice.setup(config: settings)
                result(true)
           case "get":
               // request new data manually
               let success = service.get()
               result(success)
           case "isRunning":
                result(isRunning)
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
        callback for the Service to communicate back to Flutter
        (will be called from the Service)
        */
        func callback<T: Encodable>(_ method:String, data: T) {
            let val = toJson(data)
            channel.invokeMethod(method, arguments: String(val))
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
