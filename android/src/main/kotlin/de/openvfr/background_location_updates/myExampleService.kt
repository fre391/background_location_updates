package de.openvfr.background_location_updates

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.gson.GsonBuilder
import com.google.gson.reflect.TypeToken
import android.util.Log
import kotlin.math.roundToLong

class myExampleService : mService() {

    companion object {
        fun startService(context: Context, intent: Intent) {
            ContextCompat.startForegroundService(context, intent)
        }
        fun stopService(context: Context) {
            val stopIntent = Intent(context, myExampleService::class.java)
            context.stopService(stopIntent)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId);
        var jsonSettings: String? = intent?.getStringExtra("settings")
        val gson = GsonBuilder().create()
        val settings = gson.fromJson<Map<String, Any>>(jsonSettings, object : TypeToken<Map<String, Any>>() {}.type)
        var interval: Long = 5000 //(settings["intervalMilliSeconds"]as Double).toBigDecimal().toLong()
        val mainHandler = Handler(Looper.getMainLooper())
        mainHandler.post(object : Runnable {
            override fun run() {
                if (isRunning){
                    val value = getValue()
                    onData("onData", arrayOf(value))
                    mainHandler.postDelayed(this, interval)
                }
            }
        })
        return START_NOT_STICKY
    }

    // generate random 8 digits
    fun getValue():Int{
        return (10000000..99999999).random()
    }
}