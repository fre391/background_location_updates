package de.openvfr.background_location_updates

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat
import com.google.gson.Gson
import com.google.gson.GsonBuilder

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry


/** BackgroundLocationUpdatesPlugin */
public class BackgroundLocationUpdatesPlugin : FlutterPlugin, PluginRegistry.RequestPermissionsResultListener, MethodCallHandler, ActivityAware {
    private lateinit var context: Context
    private lateinit var activity: Activity
    lateinit var channel: MethodChannel
    var handleOfFlutterCallback: Long = 0
    var isRunning: Boolean = false

    var settingsLocationUpdates:String = ""

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.getFlutterEngine().dartExecutor.binaryMessenger, "de.openvfr.background_location_updates")
        channel.setMethodCallHandler(this);
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity;
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        //activity = null
        // stop Service automatically, when app exits
        myExampleService.stopService(context)
        myLocationService.stopService(context)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val fgChannel = MethodChannel(registrar.messenger(), "de.openvfr.background_location_updates")
            fgChannel.setMethodCallHandler(BackgroundLocationUpdatesPlugin())
            val BackgroundLocationUpdatesPlugin = BackgroundLocationUpdatesPlugin()
            registrar.addRequestPermissionsResultListener(BackgroundLocationUpdatesPlugin)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "start" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(activity,
                                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,
                                        Manifest.permission.ACCESS_COARSE_LOCATION), 101)

                        result.success(this.stop())
                    } else {
                        result.success(this.start())
                    }
                } else {
                    result.success(this.start())
                }
            }
            "stop" -> {
                result.success(this.stop())
            }
            "getLocation" -> {
                if (!isRunning){
                    val startIntent2 = Intent(context, myLocationService::class.java)
                    startIntent2.putExtra("handleID", handleOfFlutterCallback)
                    startIntent2.putExtra("settings", settingsLocationUpdates)
                    startIntent2.putExtra("continousUpdates", "false")
                    myLocationService.startService(context, startIntent2)
                }
            }
            "locationSettings" -> {
                settingsLocationUpdates = call.arguments.toString()
            }
            "getValue" -> {
                // request new data manually
                var cs = myExampleService()
                val value = cs.getValue()
                channel.invokeMethod("onData", toJson(arrayOf(value)))
                result.success(value)
            }
            "isRunning" -> {
                result.success(isRunning)
            }
            "initialize" -> {
                // get the FlutterCallbackHandle, later we'll send it to the Service (when started)
                if (handleOfFlutterCallback == 0L) handleOfFlutterCallback = call.arguments.toString().toLong()
            }
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> { // Note the block
                print("not implemented")
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        when (requestCode) {
            101 -> {
                if (grantResults!!.size > 0 && grantResults.get(0).equals(PackageManager.PERMISSION_GRANTED)) {
                    Log.i("TAG", "Permission has been granted by user")
                    this.start()
                    return true
                } else {
                    Log.i("TAG", "Permission has been denied by user")
                    this.stop()
                    return false
                }
            }
        }
        return false
    }

    fun start(): Boolean {
        // start the Service manually, also send the FlutterCallbackHandler
        val startIntent1 = Intent(context, myExampleService::class.java)
        startIntent1.putExtra("handleID", handleOfFlutterCallback)
        startIntent1.putExtra("settings", settingsLocationUpdates)
        myExampleService.startService(context, startIntent1)

        val startIntent2 = Intent(context, myLocationService::class.java)
        startIntent2.putExtra("handleID", handleOfFlutterCallback)
        startIntent2.putExtra("settings", settingsLocationUpdates)
        startIntent2.putExtra("continousUpdates", "true")
        myLocationService.startService(context, startIntent2)

        isRunning = true;
        channel.invokeMethod("onStatus", toJson(arrayOf(isRunning)))
        return isRunning
    }

    fun stop(): Boolean {
        // stop Service manually
        myExampleService.stopService(context)
        myLocationService.stopService(context)
        isRunning = false;
        channel.invokeMethod("onStatus", toJson(arrayOf(isRunning)))
        return isRunning
    }

    fun toJson(value: Any): String {
        val gson = GsonBuilder().disableHtmlEscaping().create()
        return gson.toJson(value)
    }
}
