import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let getInstance: LocationService = LocationService()
    let application: UIApplication = UIApplication.shared
    var channel = FlutterMethodChannel()
     
    let locationManager = CLLocationManager()
      
    func setup(channel:FlutterMethodChannel){
        
        self.channel = channel
        
        // configure location updates
        locationManager.delegate = self
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.0
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var l = mLocation()
        l.latitude = locations[locations.count-1].coordinate.latitude
        l.longitude = locations[locations.count-1].coordinate.longitude
        l.altitude = locations[locations.count-1].altitude
        l.bearing = locations[locations.count-1].course
        l.speed = Float(locations[locations.count-1].speed)
        l.accuracy = [  Float(locations[locations.count-1].horizontalAccuracy),
                        Float(locations[locations.count-1].verticalAccuracy), 0.0]
        self.onLocation(location: l)
     }
    
    func start() -> Bool{
        return false
    }
    
    func stop() -> Bool{
        return false
    }
    
    func onLocation(location: mLocation){
        DispatchQueue.main.async {
             self.callback("onLocation", data:location)
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

public struct mLocation: Codable {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var altitude: Double = 0.0
    var bearing: Double = 0.0
    var speed: Float = 0.0
    var accuracy: [Float] = [0.0, 0.0, 0.0]
    var isMocked: Bool = false
}
