package de.openvfr.background_location_updates

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import com.google.gson.GsonBuilder
import com.google.gson.reflect.TypeToken

class myLocationService: mService() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    lateinit var locationRequest: LocationRequest
    lateinit var locationCallback: LocationCallback
    var continousUpdates = false

    companion object {
        fun startService(context: Context, intent: Intent) {
            ContextCompat.startForegroundService(context, intent)
        }
        fun stopService(context: Context) {
            val stopIntent = Intent(context, myLocationService::class.java)
            context.stopService(stopIntent)
        }
    }

    @SuppressLint("MissingPermission")
    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this!!)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        var jsonSettings: String? = intent?.getStringExtra("settings")
        val gson = GsonBuilder().create()
        val mapSettings = gson.fromJson<Map<String, Any>>(jsonSettings, object : TypeToken<Map<String, Any>>() {}.type)
        startLocationUpdates(mapSettings)
        return Service.START_STICKY
    }

    //start location updates
    @SuppressLint("MissingPermission")
    private fun startLocationUpdates(mapSettings: Map<String, Any>) {
        continousUpdates = true
        setLocationRequest(mapSettings)
        setLocationCallback(mapSettings)
        fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                null /* Looper */
        )
    }

    private fun requestLocationUpdate(mapSettings: Map<String, Any>){
        continousUpdates = false
        setLocationRequest(mapSettings)
        setLocationCallback(mapSettings)
        fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                null /* Looper */
        )
    }

    private fun setLocationRequest(mapSettings: Map<String, Any>){
        locationRequest = LocationRequest()
        locationRequest.fastestInterval = mapSettings["intervalMilliSeconds"] as? Long ?: 1000
        
        locationRequest.interval = mapSettings["intervalMilliSeconds"] as? Long ?: 1000
        locationRequest.smallestDisplacement = mapSettings["distanceFilterMeter"] as? Float ?: 0.0f
        var accuracy : Any = mapSettings["accuracy"].toString()
        when(accuracy) {
            "LocationAccuracy.powerSave" -> accuracy = LocationRequest.PRIORITY_NO_POWER
            "LocationAccuracy.low" -> accuracy = LocationRequest.PRIORITY_LOW_POWER
            "LocationAccuracy.balanced" -> accuracy = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
            "LocationAccuracy.high" -> accuracy = LocationRequest.PRIORITY_HIGH_ACCURACY
            "LocationAccuracy.navigation" -> accuracy = LocationRequest.PRIORITY_HIGH_ACCURACY
            else -> accuracy = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
        }
        locationRequest.priority = accuracy
    }

    private fun setLocationCallback(mapSettings: Map<String, Any>){
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult?) {
                locationResult ?: return

                if (locationResult.locations.isNotEmpty()) {
                    val location : Location = locationResult.lastLocation

                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2){
                        val mockDetection = mapSettings["mockUpDetection"] as? Boolean ?: true
                        if (location.isFromMockProvider  && mockDetection) return
                    }
                        
                    var locationStr:String = location.latitude.toString() + " / " + location.longitude.toString();
                    Log.i("myLocationService", locationStr)

                    var l =  mLocation()
                    l.latitude = location.latitude
                    l.longitude = location.longitude
                    l.altitude = location.altitude
                    l.bearing = location.bearing.toDouble()
                    l.speed = location.speed
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O)
                        l.accuracy = arrayOf(location.accuracy, location.verticalAccuracyMeters, location.speedAccuracyMetersPerSecond)
                    else l.accuracy = arrayOf(location.accuracy, 0.0f, 0.0f)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2)
                        l.isMocked = location.isFromMockProvider

                    onLocation(l)
                    if(!continousUpdates) {
                        stopLocationUpdates()
                        onDestroy()
                    }
                }
            }
        }
    }
    
    // stop location updates
    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }

    // send data to Flutter via backgroundChannel
    fun onLocation(location: mLocation){
        super.onData("onLocation", location)
    }

    override fun onDestroy() {
        stopLocationUpdates()
        super.onDestroy()
    }
}

class mLocation {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var altitude:Double = 0.0
    var bearing: Double = 0.0
    var speed: Float = 0.0f
    var accuracy = arrayOf(0.0f, 0.0f, 0.0f)
    var isMocked: Boolean = false
}