import '../models/celestial_object.dart';

abstract class SkyState {}

class SkyLoading extends SkyState {}

class SkyLoaded extends SkyState {
  final List<CelestialObject> celestialObjects;
  final double phoneAzimuth;   
  final double phoneAltitude;  

  SkyLoaded({
    required this.celestialObjects,
    this.phoneAzimuth  = 180, // default facing south
    this.phoneAltitude = 45, // default tilted up
  });
}


class SkyError extends SkyState {
  final String message;

  SkyError(this.message);
}