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

  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  StreamSubscription? _accelSub;
  StreamSubscription? _magSub;

  void start() {
    _accelSub = accelerometerEventStream().listen((event) {
      _accelerometer = [event.x, event.y, event.z];
      _update();
    });

    _magSub = magnetometerEventStream().listen((event) {
      _magnetometer = [event.x, event.y, event.z];
      _update();
    });

    Timer.periodic(const Duration(milliseconds: 100), (_) { // 100ms = 10 times/second
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

    // Altitude — how much you tilt the phone up/down
    // Works correctly when holding phone upright (portrait mode)
    final double altitude = math.atan2(
      ay,                          
      math.sqrt(ax * ax + az * az), 
    ) * (180 / math.pi);


    // Calculate azimuth (compass direction)
    // East vector = magnetometer cross accelerometer
    final ex = ay * mz - az * my;
    final ey = az * mx - ax * mz;
    // ez = ax * my - ay * mx; // not needed

    double azimuth = math.atan2(ey, ex) * (180 / math.pi);
    azimuth = (azimuth + 360) % 360; // normalize to 0-360

    // // Calculate altitude (tilt angle)
    // final double altitude = math.atan2(
    //   -ax,
    //   math.sqrt(ay * ay + az * az),
    // ) * (180 / math.pi);

    // print('📡 Sensor update: az=$azimuth alt=$altitude'); 
    _controller.add(SensorData(azimuth: azimuth, altitude: altitude));
  }

  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _controller.close();
  }
}
