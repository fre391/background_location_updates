library background_location_updates;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

part 'src/types.dart';

/*
ToDo: Enable mockDetection 
ToDo: Implementation of mockedLocation Detection
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
  Function listener;

  //static const MethodChannel _channel = const MethodChannel('background_location_updates');
  static const foregroundChannel = const MethodChannel("com.example.service");
  ReceivePort port = ReceivePort();

  static Future<String> get platformVersion async {
    final String version = await foregroundChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  void init(Function listener) async {
    this.listener = listener;

    /* 
    set the callback for the services 
    used by IOS Native when in foreground and/or background (IOS) 
    used by Android NAtive when in foreground only
    */
    foregroundChannel.setMethodCallHandler((call) => this.callback(call));

    /* 
    register the IsolateNameServer to be called from the BackgroudReceiver and
    call Android Native to initialize the Android Service (used by Android in background only) 
    */
    IsolateNameServer.registerPortWithName(port.sendPort, 'com.example.background_isolate');
    port.listen((dynamic call) => this.callback(call));

    final cb = PluginUtilities.getCallbackHandle(backgroudReceiver);
    await foregroundChannel.invokeMethod('initialize', cb.toRawHandle());
  }

  // ignore: missing_return
  Future<dynamic> callback(call) {
    var method = call.method;
    var args = jsonDecode(call.arguments);
    var data;
    switch (method) {
      case "onMessage":
        data = args;
        break;
      case "onLocation":
        Location location = new Location();
        location.latitude = args['latitude'].toDouble();
        location.longitude = args['longitude'].toDouble();
        location.altitude = args['altitude'].toDouble();
        location.bearing = args['bearing'].toDouble();
        location.speed = args['speed'].toDouble();
        location.accuracy = [
          args['accuracy'][0].toDouble(),
          args['accuracy'][1].toDouble(),
          args['accuracy'][2].toDouble()
        ];
        location.isMocked = args['isMocked'];
        data = location;
        break;
      case "onData":
        data = args[0];
        break;
      case "onStatus":
        data = args[0];
        break;
    }
    listener(method, data);
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
