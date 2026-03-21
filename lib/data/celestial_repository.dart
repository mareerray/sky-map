import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/celestial_object.dart';
import 'astronomy_api_service.dart';

class CelestialRepository {
  final _api = AstronomyApiService();

  Future<List<CelestialObject>> loadCelestialObjects() async {
    // 1️⃣ Real positions from AstronomyAPI
    final List<CelestialObject> realObjects = await _api.fetchBodies();

    // 2️⃣ Constellations from JSON
    final String jsonString =
        await rootBundle.loadString('assets/celestial_data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    final List<CelestialObject> constellationObjects =
        (jsonData['constellations'] as List)
            .map((c) => CelestialObject.fromJson(c))
            .toList();

    // 3️⃣ Background stars from JSON
    final List<CelestialObject> backgroundStarObjects =
        (jsonData['background_stars'] as List).asMap().entries.map((entry) {
      return CelestialObject(
        id:          'bg_star_${entry.key}',
        name:        '',
        type:        'background_star',
        description: '',
        azimuth:     (entry.value['azimuth'] as num).toDouble(),
        altitude:    (entry.value['altitude'] as num).toDouble(),
      );
    }).toList();

    return [...realObjects, ...constellationObjects, ...backgroundStarObjects];
  }
}
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import '../models/celestial_object.dart';

// class CelestialRepository {
//   Future<List<CelestialObject>> loadCelestialObjects() async {
//   final String jsonString =
//       await rootBundle.loadString('assets/celestial_data.json');
//   final Map<String, dynamic> jsonData = json.decode(jsonString);

//   final List objects = jsonData['objects'];
//   final List<CelestialObject> celestialObjects =
//       objects.map((o) => CelestialObject.fromJson(o)).toList();

//   final List constellations = jsonData['constellations'];
//   final List<CelestialObject> constellationObjects =
//       constellations.map((c) => CelestialObject.fromJson(c)).toList();

//   // Parse background stars
//   final List bgStars = jsonData['background_stars'];
//   final List<CelestialObject> backgroundStarObjects =
//       bgStars.asMap().entries.map((entry) {
//     return CelestialObject(
//       id: 'bg_star_${entry.key}',
//       name: '',
//       type: 'background_star',
//       description: '',
//       azimuth: (entry.value['azimuth'] as num).toDouble(),
//       altitude: (entry.value['altitude'] as num).toDouble(),
//     );
//   }).toList();

//   return [...celestialObjects, ...constellationObjects, ...backgroundStarObjects];
// }

  // // Loads and parses the local JSON file, returns list of celestial objects
  // Future<List<CelestialObject>> loadCelestialObjects() async {
  //   // Read the raw JSON string from the assets folder
  //   final String jsonString =
  //       await rootBundle.loadString('assets/celestial_data.json');

  //   // Decode the string into a Dart Map
  //   final Map<String, dynamic> jsonData = json.decode(jsonString);

  //   // Parse regular objects (planets, sun, moon)
  //   final List objects = jsonData['objects'];
  //   final List<CelestialObject> celestialObjects =
  //       objects.map((o) => CelestialObject.fromJson(o)).toList();

  //   // Parse constellations
  //   final List constellations = jsonData['constellations'];
  //   final List<CelestialObject> constellationObjects =
  //       constellations.map((c) => CelestialObject.fromJson(c)).toList();

  //   // Combine both lists and return
  //   return [...celestialObjects, ...constellationObjects];
  // }
//}
