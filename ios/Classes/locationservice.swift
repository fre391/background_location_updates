import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let getInstance: LocationService = LocationService()
    let locationManager = CLLocationManager()
    var settings = mLocationSettings(accuracy: "LocationAccuracy.high", intervalMilliSeconds:1000, distanceFilterMeter: 0, mockUpDetection: false)
    var delegate: ClassBDelegate!
    var isRunning = false;
    var lastLocation : mLocation = mLocation()
    var continousUpdates = false;
    
    func setup(config: String){
        
        if (config != "defaults"){
            let data: Data? = config.data(using: .utf8)
            settings = try! JSONDecoder().decode(mLocationSettings.self, from: data!)
        }
        
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
        lastLocation.latitude = locations[locations.count-1].coordinate.latitude
        lastLocation.longitude = locations[locations.count-1].coordinate.longitude
        lastLocation.altitude = locations[locations.count-1].altitude
        lastLocation.bearing = locations[locations.count-1].course
        lastLocation.speed = Float(locations[locations.count-1].speed)
        lastLocation.accuracy = [  Float(locations[locations.count-1].horizontalAccuracy),
                        Float(locations[locations.count-1].verticalAccuracy), 0.0]
        
        if (settings.mockUpDetection){
            // experimental: https://stackoverflow.com/questions/29232427/ios-detect-mock-locations
            if (lastLocation.accuracy[0] == 5 && lastLocation.accuracy[1] == -1 &&
                lastLocation.altitude == 0 && lastLocation.speed == -1) {
                lastLocation.isMocked = true
                return
            }
        }
     }
    
    func start(){
        continousUpdates = true;
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        isRunning = true
        print("ios: LocationManager started")
        getLocationUpdates()
    }
    
    func getLocation(){
        continousUpdates = false
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        isRunning = true
        print("ios: LocationManager started")
        getLocationUpdates()
    }
    
    func stop(){
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        isRunning = false
        print("ios: LocationManager stopped")
    }
    
    func getLocationUpdates(){
        DispatchQueue.global(qos: .background).async {
            while self.isRunning {
                DispatchQueue.main.async {
                    if let delegate = self.delegate {
                        delegate.callback("onLocation", data: self.lastLocation)
                    }
                }
                if !self.continousUpdates {self.isRunning = false}
                let interval = UInt32(self.settings.intervalMilliSeconds/1000)
                sleep(interval)
            }
            self.stop()
        }
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
