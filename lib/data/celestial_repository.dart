// GPS → AstronomyAPI → constellations + background stars → done ✅
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/celestial_object.dart';
import 'astronomy_api_service.dart';

class CelestialRepository {
  final _api = AstronomyApiService();

  Future<List<CelestialObject>> loadCelestialObjects() async {
    // 1️⃣ Get real GPS location
    await Geolocator.requestPermission();
    final position = await Geolocator.getCurrentPosition();
    print('📍 GPS: lat=${position.latitude}, lon=${position.longitude}');

    // 2️⃣ Real positions from AstronomyAPI using GPS
    final List<CelestialObject> realObjects = await _api.fetchBodies(
      latitude:  position.latitude,
      longitude: position.longitude,
      elevation: position.altitude,
    );

    // 3️⃣ Constellations from JSON
    final String jsonString =
        await rootBundle.loadString('assets/celestial_data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    final List<CelestialObject> constellationObjects =
        (jsonData['constellations'] as List)
            .map((c) => CelestialObject.fromJson(c))
            .toList();

    // 4️⃣ Background stars from JSON
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
// import 'package:geolocator/geolocator.dart';
// import '../models/celestial_object.dart';
// import 'astronomy_api_service.dart';
// import 'astro_calculator.dart';
// import 'package:astronomia/planetposition.dart';

// class CelestialRepository {
//   final _api = AstronomyApiService();

//   Future<List<CelestialObject>> loadCelestialObjects() async {
//     // 1️⃣ Get real GPS location
//     await Geolocator.requestPermission();
//     final position = await Geolocator.getCurrentPosition();
//     print('📍 GPS: lat=${position.latitude}, lon=${position.longitude}');

//     // 2️⃣ Try API first, fall back to local calculator
//     List<CelestialObject> realObjects;
//     try {
//       realObjects = await _api.fetchBodies(
//         latitude:  position.latitude,
//         longitude: position.longitude,
//         elevation: position.altitude,
//       );
//       print('✅ Using AstronomyAPI data');
//     } catch (e) {
//       print('⚠️ API failed, using local calculator: $e');
//       realObjects = _calculateLocally(
//         lat: position.latitude,
//         lon: position.longitude,
//       );
//     }

//     // 3️⃣ Constellations from JSON
//     final String jsonString =
//         await rootBundle.loadString('assets/celestial_data.json');
//     final Map<String, dynamic> jsonData = json.decode(jsonString);

//     final List<CelestialObject> constellationObjects =
//         (jsonData['constellations'] as List)
//             .map((c) => CelestialObject.fromJson(c))
//             .toList();

//     // 4️⃣ Background stars from JSON
//     final List<CelestialObject> backgroundStarObjects =
//         (jsonData['background_stars'] as List).asMap().entries.map((entry) {
//       return CelestialObject(
//         id:          'bg_star_${entry.key}',
//         name:        '',
//         type:        'background_star',
//         description: '',
//         azimuth:     (entry.value['azimuth'] as num).toDouble(),
//         altitude:    (entry.value['altitude'] as num).toDouble(),
//       );
//     }).toList();

//     return [...realObjects, ...constellationObjects, ...backgroundStarObjects];
//   }

//   // 🔭 Local fallback using AstroCalculator (no internet needed)
//   List<CelestialObject> _calculateLocally({
//     required double lat,
//     required double lon,
//   }) {
//     final calc = AstroCalculator(latDeg: lat, lonDeg: lon);

//     final bodies = <Map<String, dynamic>>[
//       {'id': 'sun',     'name': 'Sun',     'pos': calc.getSun()},
//       {'id': 'moon',    'name': 'Moon',    'pos': calc.getMoon()},
//       {'id': 'mercury', 'name': 'Mercury', 'pos': calc.getPlanet(Planet(planetMercury))},
//       {'id': 'venus',   'name': 'Venus',   'pos': calc.getPlanet(Planet(planetVenus))},
//       {'id': 'mars',    'name': 'Mars',    'pos': calc.getPlanet(Planet(planetMars))},
//       {'id': 'jupiter', 'name': 'Jupiter', 'pos': calc.getPlanet(Planet(planetJupiter))},
//       {'id': 'saturn',  'name': 'Saturn',  'pos': calc.getPlanet(Planet(planetSaturn))},
//       {'id': 'uranus',  'name': 'Uranus',  'pos': calc.getPlanet(Planet(planetUranus))},
//       {'id': 'neptune', 'name': 'Neptune', 'pos': calc.getPlanet(Planet(planetNeptune))},
//     ];

//     return bodies.map((body) {
//       final pos = body['pos'] as Map<String, double>;
//       return CelestialObject(
//         id:          body['id'] as String,
//         name:        body['name'] as String,
//         type:        _typeFor(body['id'] as String),
//         description: _descriptionFor(body['id'] as String),
//         azimuth:     pos['azimuth']!,
//         altitude:    pos['altitude']!,
//       );
//     }).toList();
//   }

//   String _typeFor(String id) {
//     switch (id) {
//       case 'sun':  return 'star';
//       case 'moon': return 'moon';
//       default:     return 'planet';
//     }
//   }

//   String _descriptionFor(String id) {
//     const descriptions = {
//       'sun':     'The star at the center of our Solar System.',
//       'moon':    'Earth\'s only natural satellite.',
//       'mercury': 'The smallest planet, closest to the Sun.',
//       'venus':   'The hottest planet, brightest in the night sky.',
//       'mars':    'The Red Planet.',
//       'jupiter': 'The largest planet.',
//       'saturn':  'Known for its stunning ring system.',
//       'uranus':  'An ice giant that rotates on its side.',
//       'neptune': 'The farthest planet with the strongest winds.',
//     };
//     return descriptions[id] ?? '';
//   }
// }