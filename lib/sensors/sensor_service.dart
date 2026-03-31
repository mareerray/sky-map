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

  double _lastEmittedAzimuth  = -999.00; 
  double _lastEmittedAltitude = -999.00; 
  DateTime? _lastEmitTime;

  static const double _alpha = 0.08; // 0.0 = very smooth, 1.0 = raw/jumpy
  // _alpha = 0.15 means each new reading only contributes 15% to the output 

  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  StreamSubscription? _accelSub;
  StreamSubscription? _magSub;

  void start() {
    // Force one initial emit so the sky renders immediately
    _controller.add(SensorData(azimuth: 0, altitude: 0));

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100), // ← exactly 100ms = 10/second
    ).listen((event) {
      _accelerometer = [event.x, event.y, event.z];
      _update();
    });

    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100), 
    ).listen((event) {
      _magnetometer = [event.x, event.y, event.z];
      _update();
    });
  }

  void _update() {
    final ax = _accelerometer[0];
    final ay = _accelerometer[1];
    final az = _accelerometer[2];

    final mx = _magnetometer[0];
    final my = _magnetometer[1];
    final mz = _magnetometer[2];

    // ------ Altitude Calculation — how much you tilt the phone up/down ---------
    // Works correctly when holding phone upright (portrait mode)
    final double altitude = -math.atan2(
      az,                           // Z changes when tilting toward sky
      math.sqrt(ax * ax + ay * ay),  // XY plane = base
    ) * (180 / math.pi);


    // Normalize accelerometer to get gravity direction
    final double accNorm = math.sqrt(ax*ax + ay*ay + az*az);
    final double axN = ax / accNorm;
    final double ayN = ay / accNorm;

    // Tilt-compensated magnetic North components
    final double pitch = math.asin((-axN).clamp(-1.0, 1.0)); // Tilt forward around Y-axis
    final double cosP = math.cos(pitch);
    final double sinRoll = (cosP.abs() < 0.001) ? 0.0 : (ayN / cosP).clamp(-1.0, 1.0);
    final double roll = math.asin(sinRoll); // Tilt sideways around X-axis

    final double magX = mx * math.cos(pitch) + mz * math.sin(pitch);
    final double magY = mx * math.sin(roll) * math.sin(pitch)
                      + my * math.cos(roll)
                      - mz * math.sin(roll) * math.cos(pitch);

    // ------ Azimuth Calculation — which direction you’re facing (0-360°)/Compass direction ---------
    double azimuth = math.atan2(-magX, magY) * (180 / math.pi);
    azimuth = (azimuth + 360) % 360; // normalize to 0-360

    // Add declination correction 
    const double declination = 10.0; 
    azimuth = (azimuth - declination + 360) % 360;

    // ------ Smooth it out to prevent jitter -----------------
    double azDelta = ((azimuth - _smoothAzimuth) + 540) % 360 - 180; // finds the shortest path between two angles
    final azChange = azDelta.abs();
    if (azChange > 0.5) { // only smooth if changed >0.5°
      _smoothAzimuth = (_smoothAzimuth + _alpha * azDelta + 360) % 360;
    }
    _smoothAltitude = _alpha * altitude + (1 - _alpha) * _smoothAltitude;

    final azDiff =
    ((_smoothAzimuth - _lastEmittedAzimuth) + 540) % 360 - 180;
    final altDiff = (_smoothAltitude - _lastEmittedAltitude).abs();

    final now = DateTime.now();
    final shouldEmitByTime = _lastEmitTime == null ||
        now.difference(_lastEmitTime!).inMilliseconds >= 100;
    final shouldEmitByMovement =
        azDiff.abs() > 1.5 || altDiff > 1.5;

    if (shouldEmitByMovement || shouldEmitByTime) {
      _lastEmittedAzimuth = _smoothAzimuth;
      _lastEmittedAltitude = _smoothAltitude;
      _lastEmitTime = now;

      _controller.add(SensorData(
        azimuth: _smoothAzimuth, 
        altitude: _smoothAltitude, 
      ));
    }
  }

  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _controller.close();
  }
}
