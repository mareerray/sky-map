// lib/screens/test_sky.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sky_map/models/celestial_object.dart';
import '../data/celestial_repository.dart';
import '../data/astro_calculator.dart';
import '../ui/sky_painter.dart';

class TestSkyScreen extends StatefulWidget {
  const TestSkyScreen({super.key});
  @override
  State <TestSkyScreen> createState() => _TestSkyScreenState();
}

class _TestSkyScreenState extends State<TestSkyScreen> {
  List<CelestialObject> objects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final repo = CelestialRepository();
    final position = await Geolocator.getCurrentPosition();
    final astro = AstroCalculator(latDeg: position.latitude, lonDeg: position.longitude);
    
    final loadedObjects = await repo.loadCelestialObjects(); // your method
    setState(() {
      objects = loadedObjects.where((obj) => obj.altitude > 0).toList(); // only above horizon
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Test Sky - ${objects.length} objects')),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : CustomPaint(
            size: Size.infinite,
            painter: SkyPainter(
              objects: objects,
              phoneAzimuth: 180, // facing south for testing
              phoneAltitude: 45,
            ),
          ),
    );
  }
}
