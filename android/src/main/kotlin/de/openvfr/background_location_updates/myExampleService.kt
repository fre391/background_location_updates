package de.openvfr.background_location_updates

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat

class myExampleService : mService() {

    companion object {
        fun startService(context: Context, intent: Intent) {
            var handleID: Long = intent!!.getLongExtra("handleID", 0L)
            val startIntent = Intent(context, myExampleService::class.java)
            startIntent.putExtra("handleID", handleID)
            ContextCompat.startForegroundService(context, startIntent)
        }
        fun stopService(context: Context) {
            val stopIntent = Intent(context, myExampleService::class.java)
            context.stopService(stopIntent)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId);
        val mainHandler = Handler(Looper.getMainLooper())
        mainHandler.post(object : Runnable {
            override fun run() {
                if (isRunning){
                    val value = getValue()
                    onData("onData", arrayOf(value))
                    mainHandler.postDelayed(this, 1000)
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