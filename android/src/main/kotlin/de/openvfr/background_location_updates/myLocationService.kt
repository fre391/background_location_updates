package de.openvfr.background_location_updates

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent.getActivity
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*

class myLocationService: mService() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    lateinit var locationRequest: LocationRequest
    lateinit var locationCallback: LocationCallback

    companion object {
        fun startService(context: Context, intent: Intent) {
            var handleID: Long = intent!!.getLongExtra("handleID", 0L)
            val startIntent = Intent(context, myLocationService::class.java)
            startIntent.putExtra("handleID", handleID)
            ContextCompat.startForegroundService(context, startIntent)
        }
        fun stopService(context: Context) {
            val stopIntent = Intent(context, myLocationService::class.java)
            context.stopService(stopIntent)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startLocationUpdates()
        return Service.START_STICKY
    }

    @SuppressLint("MissingPermission")
    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this!!)
        locationRequest = LocationRequest()
        locationRequest.interval = 1000
        locationRequest.fastestInterval = 1000
        locationRequest.smallestDisplacement = 0f // 170 m = 0.1 mile
        locationRequest.priority = LocationRequest.PRIORITY_HIGH_ACCURACY //set according to your app function
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult?) {
                locationResult ?: return

                if (locationResult.locations.isNotEmpty()) {
                    val location : Location = locationResult.lastLocation
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2)
                        if (location.isFromMockProvider) return
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
                    else l.accuracy = arrayOf(location.accuracy,0.0f, 0.0f)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2)
                        l.isMocked = location.isFromMockProvider

                    onLocation(l)
                }
            }
        }
    }

    //start location updates
    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                null /* Looper */
        )
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
    var accuracy = arrayOf(0.0f,0.0f, 0.0f)
    var isMocked: Boolean = false
}