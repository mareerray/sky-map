import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/celestial_repository.dart';
import '../sensors/sensor_service.dart';
import 'sky_event.dart';
import 'sky_state.dart';

class SkyBloc extends Bloc<SkyEvent, SkyState> { // tells Flutter: "this BLoC accepts SkyEvents and produces SkyStates"

  final CelestialRepository repository;
  final SensorService _sensorService = SensorService();
  StreamSubscription? _sensorSubscription;


  // SkyInitial is the very first state before anything happens
  SkyBloc(this.repository) : super(SkyLoading()) { // the starting state when BLoC is first created

    // Load sky objects
    on<LoadSkyObjects>((event, emit) async { // a listener that wakes up only when LoadSkyObjects event arrives
      emit(SkyLoading()); // Tell UI: "I'm working on it..."

      try {
        final objects = await repository.loadCelestialObjects();
        emit(SkyLoaded(celestialObjects: objects)); // Tell UI: "Here is your data!"
        // Start sensors AFTER data is loaded
        _startSensors();
      } catch (e) {
        emit(SkyError('Failed to load sky data: $e')); // Tell UI: "Something broke!"
      }
    });

    // React to sensor updates
    on<SensorUpdated>((event, emit) {
        print('🧭 BLoC: az=${event.azimuth.toStringAsFixed(1)}°');      if (state is SkyLoaded) {
        final current = state as SkyLoaded;
        emit(SkyLoaded(
          celestialObjects: current.celestialObjects,
          phoneAzimuth:  event.azimuth,
          phoneAltitude: event.altitude,
        ));
      }
    });  
  }

  void _startSensors() {
    _sensorService.start();
    _sensorSubscription = _sensorService.stream.listen((data) {
      add(SensorUpdated(
        azimuth:  data.azimuth,
        altitude: data.altitude,
      ));
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