part of background_location_updates;

class Location {
  double latitude = 0.0;
  double longitude = 0.0;
  double altitude = 0.0;
  double bearing = 0.0;
  double speed = 0.0;
  List<double> accuracy = [0.0, 0.0, 0.0];
  bool isMocked = false;
}

enum LocationAccuracy {
  /// To request best accuracy possible with zero additional power consumption
  powerSave,

  /// To request "city" level accuracy
  low,

  /// To request "block" level accuracy
  balanced,

  /// To request the most accurate locations available
  high,

  /// To request location for navigation usage (affect only iOS)
  navigation,
}
