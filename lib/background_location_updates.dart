library background_location_updates;

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

part 'src/types.dart';

/*
ToDo: Implementation of mockedLocation Detection and filter by userSetting
  https://stackoverflow.com/questions/29232427/ios-detect-mock-locations
  horizontalAccuracy: 5
  verticalAccuracy: -1
  altitude: 0.000000
  speed: -1
ToDo: start/stop each service seperately (notifications?)
ToDo: compassImplementation
ToDo: interval for RandomService
*/

/* 
Define a callback for Android Native only, when calling from background.
It will use the IsolateNameServer in Flutter to finally call the callback
*/
void backgroudReceiver() {
  MethodChannel backgroundChannel = MethodChannel('com.example.background_service');
  WidgetsFlutterBinding.ensureInitialized();

  backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final SendPort send = IsolateNameServer.lookupPortByName('com.example.background_isolate');
    send?.send(call);
  });
}

class BackgroundLocationUpdates {
  //static const MethodChannel _channel = const MethodChannel('background_location_updates');
  static const foregroundChannel = const MethodChannel("com.example.service");
  ReceivePort port = ReceivePort();

  static Future<String> get platformVersion async {
    final String version = await foregroundChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  void init(Function appCallback) async {
    /* 
    set the callback for the services 
    used by IOS Native when in foreground and/or background (IOS) 
    used by Android NAtive when in foreground only
    */
    foregroundChannel.setMethodCallHandler((call) => appCallback(call));

    /* 
    register the IsolateNameServer to be called from the BackgroudReceiver and
    call Android Native to initialize the Android Service (used by Android in background only) 
    */
    IsolateNameServer.registerPortWithName(port.sendPort, 'com.example.background_isolate');
    port.listen((dynamic call) => appCallback(call));

    final callback = PluginUtilities.getCallbackHandle(backgroudReceiver);
    await foregroundChannel.invokeMethod('initialize', callback.toRawHandle());
  }

  void setLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int intervalMilliSecondsAndroid = 1000,
    double distanceFilterMeter = 0,
  }) async {
    String json =
        "{'accuracy': '$accuracy', 'intervalMilliSeconds': $intervalMilliSecondsAndroid, 'distanceFilterMeter': $distanceFilterMeter}";
    await foregroundChannel.invokeMethod("locationSettings", json);
  }

  void start() async {
    await foregroundChannel.invokeMethod("start");
  }

  void stop() async {
    await foregroundChannel.invokeMethod("stop");
  }

  void get() async {
    await foregroundChannel.invokeMethod("get");
  }
}
