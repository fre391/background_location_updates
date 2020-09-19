# Background Location Updates for Flutter (background_location_updates)

A Flutter plugin for getting location updates even when the app is in background, but not killed.

- Native Android, written in Kotlin

- IOS, written in Swift

```diff
Please note: Dont't use in production. Currently this flutter plugin is under construction.
```

## Overview
This flutter plugin will request location updates and an additional payload (at the moment to generate a sequence a random 8 digit integer each second). It needs to be started / stopped by the user. As a confirmation a notification will be sent. It will run in fore- and background and automatically stops when app exits.

## Screenshot
<img src="https://github.com/fre391/background_location_updates/blob/master/imgs/screenshot.png" width="270" height="565"> 


## Installation 

1. Add dependency at pubspec.yaml
```diff
dependencies:
  flutter:
    sdk: flutter
  background_location_updates:
    git:...[will follow soon]
  permission_handler: ^5.0.1+1  # used for permission handling
  flutter_beep: ^0.2.0          # (optional) for testing purpose
  flutter_map: ^0.10.1+1        # (optional) for testing purpose
```

2. Add permissions at Android: android/app/src/AndroidManifest.xml
```diff
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

3. Add permissions at IOS:  ios/Runner/Info.plist
```diff
<key>NSLocationAlwaysUsageDescription</key>
<string>Program requires GPS to track cars and job orders</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Program requires GPS to track cars and job orders</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Program requires GPS to track cars and job orders</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>location</string>
    <string>processing</string>
</array>
```

## Usage in your app

1. Add imports (refer example/lib/main.dart)
```diff
import 'package:background_location_updates/background_location_updates.dart';

# used for permission handling
import 'package:permission_handler/permission_handler.dart'; 

# (optional) for testing purpose
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_beep/flutter_beep.dart';

```

2. Permissions (refer example/lib/main.dart)
```diff

init() async {
    Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.locationAlways,
        Permission.locationWhenInUse,
        Permission.notification
    ].request();
    print(statuses[Permission.location]);
}
```

3. Configuration (refer example/lib/main.dart)

```diff
locationUpdates.configureSettings(
    accuracy: LocationAccuracy.high,
    intervalMilliSecondsAndroid: 1000,
    distanceFilterMeter: 0,
    mockUpDetection: true);
```

4. Definition of callback for location updates (refer example/lib/main.dart)
```diff
BackgroundLocationUpdates locationUpdates = new BackgroundLocationUpdates();

locationUpdates.setCallback((method, args) {
  updateState(method, args);
});

```


## Implementation Details

```diff
Please note: Dont't use in production. Currently this flutter plugin is under construction.
```

Communication with Native Code:
The plugin communicates with the Native Andoid/IOS API via a MethodChannel ("channel"). 
The communication back is done via the same Methodchannel which calls the callback in Flutter.

Data Handling in IOS:
The delivery of all data is also done directly by use of the same MethodChannel (indepandantly if the app operates in foreground or in background).

Data Handling in Android:
To enable background operation on an Android device additional native services are launched to deliver all data. The native services communicate via the MethodChannel to an internal receiver ("backgroundReceiver") in Flutter. Finally the backgroundReceiver calls the callback via an internal IsolateNameServer.
