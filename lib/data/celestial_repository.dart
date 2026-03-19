import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/celestial_object.dart';

class CelestialRepository {
  // Loads and parses the local JSON file, returns list of celestial objects
  Future<List<CelestialObject>> loadCelestialObjects() async {
    // Read the raw JSON string from the assets folder
    final String jsonString =
        await rootBundle.loadString('assets/celestial_data.json');

    // Decode the string into a Dart Map
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Parse regular objects (planets, sun, moon)
    final List objects = jsonData['objects'];
    final List<CelestialObject> celestialObjects =
        objects.map((o) => CelestialObject.fromJson(o)).toList();

    // Parse constellations
    final List constellations = jsonData['constellations'];
    final List<CelestialObject> constellationObjects =
        constellations.map((c) => CelestialObject.fromJson(c)).toList();

    // Combine both lists and return
    return [...celestialObjects, ...constellationObjects];
  }
}
