import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let getInstance: LocationService = LocationService()
    let application: UIApplication = UIApplication.shared
    var channel = FlutterMethodChannel()
    let locationManager = CLLocationManager()
    var settings = mLocationSettings(accuracy: "LocationAccuracy.high", intervalMilliSeconds:1000, distanceFilterMeter: 0, mockUpDetection: false)
    
    func setup(channel:FlutterMethodChannel){
        self.channel = channel
    }
    
    func setLocationManager(config: String){
        // configure location updates
        
        if (config != "defaults"){
            let data: Data? = config.data(using: .utf8)
            settings = try! JSONDecoder().decode(mLocationSettings.self, from: data!)
        }
        
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = settings.distanceFilterMeter as Double
        var accuracy: CLLocationAccuracy
        switch (settings.accuracy) {
          case "LocationAccuracy.powerSave":
              accuracy = kCLLocationAccuracyKilometer;
          case "LocationAccuracy.city":
              accuracy = kCLLocationAccuracyHundredMeters;
          case "LocationAccuracy.balanced":
              accuracy = kCLLocationAccuracyNearestTenMeters;
          case "LocationAccuracy.high":
              accuracy = kCLLocationAccuracyBest;
          case "LocationAccuracy.navigation":
              accuracy = kCLLocationAccuracyBestForNavigation;
          default:
              accuracy = kCLLocationAccuracyBest;
        }
        locationManager.desiredAccuracy = accuracy
        
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
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
        
        
        if (settings.mockUpDetection){
            // experimental: https://stackoverflow.com/questions/29232427/ios-detect-mock-locations
            if (l.accuracy[0] == 5 && l.accuracy[1] == -1 &&
                l.altitude == 0 && l.speed == -1) {
                l.isMocked = true
                return
            }
        }
        self.onLocation(location: l)
     }
    
    func start(){
        locationManager.startUpdatingLocation()
        print("ios: LocationManager started")

    }
    
    func stop(){
        locationManager.stopUpdatingLocation()
        print("ios: LocationManager stopped")

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

struct mLocationSettings: Codable {
    let accuracy: String
    let intervalMilliSeconds: Double
    let distanceFilterMeter: Double
    let mockUpDetection: Bool
}
