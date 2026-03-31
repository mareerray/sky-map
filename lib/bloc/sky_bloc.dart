import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/celestial_repository.dart';
import '../sensors/sensor_service.dart';
import 'sky_event.dart';
import 'sky_state.dart';

class SkyBloc extends Bloc<SkyEvent, SkyState> {
  final CelestialRepository repository;
  final SensorService _sensorService = SensorService();
  StreamSubscription? _sensorSubscription;

  SkyBloc(this.repository) : super(SkyLoading()) {
    on<LoadSkyObjects>(_onLoadSkyObjects);
    on<SensorUpdated>(_onSensorUpdated);
  }

  Future<void> _onLoadSkyObjects(LoadSkyObjects event, Emitter<SkyState> emit) async {
    emit(SkyLoading());

    try {
      final objects = await repository.loadCelestialObjects();
      final lines = await repository.loadConstellationLines();  
      final imageNames = ['sun', 'mercury', 'venus', 'mars',
                        'jupiter', 'saturn', 'uranus', 'neptune',
                        'moon', 'pluto'];
      final Map<String, ui.Image> planetImages = {};
        for (final name in imageNames) {
          final img = await _loadImage('assets/images/$name.png');
          if (img != null) planetImages[name] = img; // only adds if file exists
        }
      emit(SkyLoaded(
        celestialObjects: objects,
        phoneAzimuth: 0.0,  // Default
        phoneAltitude: 45.0,
        constellationLines: lines,  // Pass JSON
        planetImages: planetImages,
      ));

      _startSensors();
    } catch (e) {
      emit(SkyError('Failed to load sky data: $e'));
    }
  }

  void _onSensorUpdated(SensorUpdated event, Emitter<SkyState> emit) {
    if (state is SkyLoaded) {
      final current = state as SkyLoaded;
      emit(SkyLoaded(
        celestialObjects: current.celestialObjects,
        phoneAzimuth: event.azimuth,
        phoneAltitude: event.altitude,
        constellationLines: current.constellationLines,  
        planetImages: current.planetImages,
      ));
    }
  }

  void _startSensors() {
    _sensorService.start();
    _sensorSubscription = _sensorService.stream.listen((data) {
      add(SensorUpdated(azimuth: data.azimuth, altitude: data.altitude));
    });
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data  = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      // print('✅ Image loaded: $assetPath');
      return frame.image;
    } catch (e) {
      // print('❌ Image failed: $e');
      return null; // if image missing, return null safely
    }
  }

  @override
  Future<void> close() {
    _sensorSubscription?.cancel();
    _sensorService.dispose();
    return super.close();
  }
}

// BLoC Flow
// 1. LoadSkyObjects → repository → SkyLoaded(objects)
// 2. _startSensors() → SensorService stream → SensorUpdated events
// 3. SensorUpdated → emit SkyLoaded(new azimuth/altitude) → screen repaints! ✨


// The Star of the Show 🌟
// - Receives the LoadSkyObjects event
// - Calls CelestialRepository to fetch the data
// - Emits SkyLoading → then SkyLoaded (or SkyError if something breaks)