import '../models/celestial_object.dart';
import 'dart:ui' as ui;

abstract class SkyState {}

class SkyLoading extends SkyState {}

class SkyLoaded extends SkyState {
  final List<CelestialObject> celestialObjects;
  final double phoneAzimuth;   
  final double phoneAltitude;  
  final Map<String, List<List<String>>> constellationLines; 
  Map<String, ui.Image> planetImages;

  SkyLoaded({
    required this.celestialObjects,
    this.phoneAzimuth  = 180, // default facing south
    this.phoneAltitude = 45, // default tilted up
    this.constellationLines = const {},
    this.planetImages = const {},
  });
}


class SkyError extends SkyState {
  final String message;

  SkyError(this.message);
}