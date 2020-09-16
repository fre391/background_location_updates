# Background Location Updates for Flutter (background_location_updates)

A Flutter plugin for getting location updates even when the app is in background, but not killed.

- Native Android, written in Kotlin

- IOS, written in Swift

```diff
Please note: Currently this flutter plugin is under construction.
```

## Overview
This flutter plugin will request location updates and an additional payload (at the moment to generate a sequence a random 8 digit integer each second). It needs to be started / stopped by the user. As a confirmation a notification will be sent. It will run in fore- and background and automatically stops when app exits.

## Screenshot
<img src="https://github.com/fre391/background_location_updates/blob/master/imgs/screenshot.png" width="270" height="565"> 


## Installation 

1. Add dependency at pubspec.yaml
```diff
background_location_updates:
    git:...[will follow soon]
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

4. Integration into you app 
```diff
refer example/lib/main.dart 
```

## Implementation Details
following soon

### Flutter / Dart
following soon

### Native Android /Kotlin 
following soon

### Native IOS / Swift
following soon


```diff
Please note: Currently this flutter plugin is under construction.
```

