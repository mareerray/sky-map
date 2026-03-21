abstract class SkyEvent {}

class LoadSkyObjects extends SkyEvent {}

class SensorUpdated extends SkyEvent {
  final double azimuth;
  final double altitude;
  SensorUpdated({required this.azimuth, required this.altitude});
}
