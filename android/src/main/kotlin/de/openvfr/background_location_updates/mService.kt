package de.openvfr.background_location_updates

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.gson.GsonBuilder
import de.openvfr.background_location_updates.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain
import io.flutter.view.FlutterNativeView

open class mService : Service() {
    val context = this

    private var backgroundFlutterView: FlutterNativeView? = null
    lateinit var backgroundChannel : MethodChannel
    var handleOfFlutterCallback: Long = 0L
    var isRunning = false;

    private var notificationManager: NotificationManager? = null
    private val NOTIFICATION_CHANNEL = "myServices"
    private val NOTIFICATION_ID = 101;

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handleOfFlutterCallback = intent!!.getLongExtra("handleID", 0L)

        /*
        If we don't have an existing background FlutterNativeView, we need to create one and
        have it initialize our Receiver in Flutter.
        */
        if (backgroundFlutterView == null && handleOfFlutterCallback != 0L) {
            FlutterMain.startInitialization(context)
            FlutterMain.ensureInitializationComplete(context, null)

            // get callbackHandle from Flutter and set it as background handler
            val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(handleOfFlutterCallback)
            val backgroundFlutterEngine = FlutterEngine(context)
            val args = DartExecutor.DartCallback(context.getAssets(),
                    FlutterMain.findAppBundlePath(context)!!, callbackInfo
            )
            backgroundFlutterEngine!!.getDartExecutor().executeDartCallback(args)
            backgroundChannel = MethodChannel(backgroundFlutterEngine!!.getDartExecutor().
            getBinaryMessenger(), "com.example.background_service")
        }

        // prepare user notification and start service
        createNotificationChannel()
        var notification = buildNotification("Service started", "Background Service running.");
        startForeground(NOTIFICATION_ID, notification)

        isRunning = true

        return START_NOT_STICKY
    }

    // user notification and destroy service
    override fun onDestroy() {
        val notification = buildNotification("Service stopped", "Background Service stopped.");
        notificationManager?.notify(NOTIFICATION_ID, notification);
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        TODO("Not yet implemented")
    }

    // send data to Flutter via backgroundChannel
    open fun onData(method: String, value: Any){
        FlutterMain.startInitialization(context)
        FlutterMain.ensureInitializationComplete(context, null)
        backgroundChannel.invokeMethod(method, toJson(value))
    }

    fun toJson(value:Any): String {
        val gson = GsonBuilder().disableHtmlEscaping().create()
        return gson.toJson(value)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(NOTIFICATION_CHANNEL, "Foreground Service Channel",
                    NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager!!.createNotificationChannel(serviceChannel)
        }
    }

    fun buildNotification(title: String, message: String): Notification {
        val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(R.drawable.common_google_signin_btn_icon_light_normal)
                .build()
        return notification
    }
}