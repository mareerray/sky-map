import 'dart:async';
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
      final lines = await repository.loadConstellationLines();  // ✅ Load here

      emit(SkyLoaded(
        celestialObjects: objects,
        phoneAzimuth: 0.0,  // Default
        phoneAltitude: 45.0,
        constellationLines: lines,  // ✅ Pass JSON
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
        constellationLines: current.constellationLines,  // ✅ Keep lines
      ));
    }
  }

  void _startSensors() {
    _sensorService.start();
    _sensorSubscription = _sensorService.stream.listen((data) {
      add(SensorUpdated(azimuth: data.azimuth, altitude: data.altitude));
    });
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