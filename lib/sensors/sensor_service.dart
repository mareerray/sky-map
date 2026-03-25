import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class SensorData {
  final double azimuth;  // horizontal direction (0-360°)
  final double altitude; // vertical tilt (0-90°)

  SensorData({required this.azimuth, required this.altitude});
}

Future<Position> getLocation() async {
  await Geolocator.requestPermission();
  return await Geolocator.getCurrentPosition();
}

class SensorService {
  // Raw sensor values
  List<double> _accelerometer = [0, 0, 9.8];
  List<double> _magnetometer  = [0, 1, 0];

  double _smoothAzimuth  = 0;
  double _smoothAltitude = 0;
  double _lastEmittedAzimuth  = -999; 
  double _lastEmittedAltitude = -999; 
  static const double _alpha = 0.05; // 0.0 = very smooth, 1.0 = raw/jumpy
  // _alpha = 0.15 means each new reading only contributes 15% to the output 

  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  StreamSubscription? _accelSub;
  StreamSubscription? _magSub;

  void start() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100), // ← exactly 100ms = 10/second
    ).listen((event) {
      _accelerometer = [event.x, event.y, event.z];
      _update();
    });

    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100), // ← same
    ).listen((event) {
      _magnetometer = [event.x, event.y, event.z];
      _update();
    });
  }

  void _update() {
    final ax = _accelerometer[0];
    final ay = _accelerometer[1];
    final az = _accelerometer[2];
    // 👇 Add this temporarily
    print('📱 ax=${ ax.toStringAsFixed(1)} ay=${ay.toStringAsFixed(1)} az=${az.toStringAsFixed(1)}');
    final mx = _magnetometer[0];
    final my = _magnetometer[1];
    final mz = _magnetometer[2];

    // Altitude — how much you tilt the phone up/down
    // Works correctly when holding phone upright (portrait mode)
    final double altitude = math.atan2(
      -ay,                          
      math.sqrt(az * az + ax * ax), 
    ) * (180 / math.pi);

    // Normalize accelerometer to get gravity direction
    final double accNorm = math.sqrt(ax*ax + ay*ay + az*az);
    final double axN = ax / accNorm;
    final double ayN = ay / accNorm;
    final double azN = az / accNorm;

    // Tilt-compensated magnetic North components
    final double pitch = math.asin(-axN);
    final double roll  = math.asin(ayN / math.cos(pitch));

    final double magX = mx * math.cos(pitch)
                      + mz * math.sin(pitch);
    final double magY = mx * math.sin(roll) * math.sin(pitch)
                      + my * math.cos(roll)
                      - mz * math.sin(roll) * math.cos(pitch);

    double azimuth = math.atan2(-magY, magX) * (180 / math.pi);
    azimuth = (azimuth + 360) % 360; // normalize to 0-360

    // // Calculate azimuth (compass direction)
    // // East vector = magnetometer cross accelerometer
    // final ex = ay * mz - az * my;
    // final ey = az * mx - ax * mz;

    // double azimuth = math.atan2(ey, ex) * (180 / math.pi);
    // azimuth = (azimuth + 180) % 360; // normalize to 0-360

    // Smooth it out
    _smoothAzimuth  = _alpha * azimuth  + (1 - _alpha) * _smoothAzimuth;
    _smoothAltitude = _alpha * altitude + (1 - _alpha) * _smoothAltitude;

    // ✅ FIX: Only emit if something changed more than 1 degree
    final azDiff  = (_smoothAzimuth  - _lastEmittedAzimuth).abs();
    final altDiff = (_smoothAltitude - _lastEmittedAltitude).abs();

    if (azDiff > 3.5 || altDiff >3.5) {
      _lastEmittedAzimuth  = _smoothAzimuth;
      _lastEmittedAltitude = _smoothAltitude;

      // print('📡 Sensor update: az=$azimuth alt=$altitude'); 
      _controller.add(SensorData(
        azimuth: _smoothAzimuth, 
        altitude: _smoothAltitude + 90.0, // Adjust so 0° = horizon, +90° = straight up
      ));
    }
  }

  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _controller.close();
  }
}
