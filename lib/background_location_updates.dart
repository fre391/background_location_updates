library background_location_updates;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

part 'src/types.dart';

/*
ToDo: get a single Location (async?)
ToDo: refactor Random to compass (incl. interval parameter)
ToDo: start/stop each service seperately (notifications?)
*/

/* 
Define a callback for Android Native only, when calling from background.
It will use the IsolateNameServer in Flutter to finally call the callback
*/
void backgroudReceiver() {
  MethodChannel channel = MethodChannel('de.openvfr.background_location_updates');
  WidgetsFlutterBinding.ensureInitialized();

  channel.setMethodCallHandler((MethodCall call) async {
    final SendPort send =
        IsolateNameServer.lookupPortByName('de.openvfr.background_location_updates');
    send?.send(call);
  });
}

class BackgroundLocationUpdates {
  Function listener;

  //static const MethodChannel _channel = const MethodChannel('background_location_updates');
  static const channel = const MethodChannel("de.openvfr.background_location_updates");
  ReceivePort port = ReceivePort();

  static Future<String> get platformVersion async {
    final String version = await channel.invokeMethod('getPlatformVersion');
    return version;
  }

  void setCallback(Function listener) async {
    this.listener = listener;

    /* 
    set the callback for the services 
    used by IOS Native when in foreground and/or background (IOS) 
    used by Android NAtive when in foreground only
    */
    channel.setMethodCallHandler((call) => this.callback(call));

    /* 
    register the IsolateNameServer to be called from the BackgroudReceiver and
    call Android Native to initialize the Android Service (used by Android in background only) 
    */
    IsolateNameServer.registerPortWithName(port.sendPort, 'de.openvfr.background_location_updates');
    port.listen((dynamic call) => this.callback(call));

    final cb = PluginUtilities.getCallbackHandle(backgroudReceiver);
    await channel.invokeMethod('initialize', cb.toRawHandle());
  }

  // ignore: missing_return
  Future<dynamic> callback(call) {
    var method = call.method;
    var args = jsonDecode(call.arguments);
    var data;
    switch (method) {
      case "onStatus":
        data = args[0];
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
      default:
        method = null;
    }
    if (method != null) listener(method, data);
  }

  void configureSettings(
      {LocationAccuracy accuracy = LocationAccuracy.high,
      int intervalMilliSecondsAndroid = 1000,
      double distanceFilterMeter = 0,
      bool mockUpDetection = true}) async {
    String json = "{" +
        "'accuracy': '$accuracy', " +
        "'intervalMilliSeconds': $intervalMilliSecondsAndroid, " +
        "'distanceFilterMeter': $distanceFilterMeter, " +
        "'mockUpDetection': $mockUpDetection" +
        "}";
    await channel.invokeMethod("locationSettings", json);
  }

  Future<bool> start() async {
    return await channel.invokeMethod("start");
  }

  Future<bool> stop() async {
    return await channel.invokeMethod("stop");
  }

  void getLocation() async {
    await channel.invokeMethod("getLocation");
  }

  void getValue() async {
    await channel.invokeMethod("getValue");
  }

  Future<bool> isRunning() async {
    return await channel.invokeMethod("isRunning");
  }
}
