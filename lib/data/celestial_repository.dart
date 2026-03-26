// GPS → AstronomyAPI → constellations + background stars → done ✅
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/celestial_object.dart';
import 'astronomy_api_service.dart';
import 'astro_calculator.dart';

class CelestialRepository {
  final _api = AstronomyApiService();

  // Your 6 chosen constellations
  static const _constellations = {'ori', 'uma', 'cas', 'leo', 'cyg', 'gem'};

  // --------------------- Load Objects from API ---------------------

  Future<List<CelestialObject>> loadCelestialObjects() async {
// 1️⃣ Get real GPS location
    await Geolocator.requestPermission();
    final position = await Geolocator.getCurrentPosition();
    final astro = AstroCalculator(
      latDeg: position.latitude, 
      lonDeg: position.longitude
    );
    print('\x1b[36m📍 GPS: lat=${position.latitude}, lon=${position.longitude}\x1b[0m');
    // 2️⃣ Real positions from AstronomyAPI using GPS
    final List<CelestialObject> realObjects = await _api.fetchBodies(
      latitude:  position.latitude,
      longitude: position.longitude,
      elevation: position.altitude,
    );

    // 3️⃣ Constellation + background stars from HYG CSV
    final List<CelestialObject> starObjects = await _loadStarsFromCsv(astro);
    final constellationLines = await loadConstellationLines();
    final groupedObjects = _groupStarsByConstellation(starObjects, constellationLines);

    // Return SkyLoaded exactly like your state expects
    return [...realObjects, ...groupedObjects, ...starObjects];
  }

  // --------------------- Load Stars from CSV file ---------------------

  Future<List<CelestialObject>> _loadStarsFromCsv(AstroCalculator astro) async {
    final rawCsv = await rootBundle.loadString('assets/hygdata_v42.csv');
    final lines = rawCsv.split('\n');

    final List<CelestialObject> stars = [];
    int processed = 0;

    for (int i = 1; i < lines.length && processed < 15000; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || !line.contains(',')) continue;

      try {
        final row = _parseCsvLine(line);
        
        // Exact column indexes from the header we saw
        final con = row[29].trim().toLowerCase();  // "con"
        final mag = double.tryParse(row[13].trim()) ?? 99.0;  // "mag"
        final raDeg   = double.tryParse(row[17].trim()) ?? 0.0;  // 🆕 ra DEGREES col 17!
        final decDeg  = double.tryParse(row[19].trim()) ?? 0.0;     
        final name    = row[6].trim();  // "proper"

        if (!_constellations.contains(con)) continue;

        // 🆕 Tiered brightness filtering
        // if (mag > 4.5) continue; // Only stars brighter than mag 4.5
        // Repository: special case important stars
        if (mag > 4.0 && !['saiph', 'merak', 'phecda'].contains(name.toLowerCase())) continue;

        final starType = 'star';

        final coords = astro.getStarHorizontal(raHours: raDeg / 15.0, decDeg: decDeg);

        final az = coords['azimuth'] ?? 0.0;
        final alt = coords['altitude'] ?? 0.0;

        stars.add(CelestialObject(
          id: 'star_$processed',
          name: name.isEmpty ? con.toUpperCase() : name,
          type: starType,
          description: 'A star in the $con constellation',
          azimuth: az,
          altitude: alt,
        ));

        processed++;
      } catch (e) {
        // Skip bad rows
      }
    }
    print('ALL STARS LOADED (${stars.length}):');
    for (var star in stars.take(20)) {  // First 20
      print('  ${star.name} (${star.description}) alt=${star.altitude}');
    }
    return stars;
  }

  // -------------- Helper method for proper CSV parsing --------------

  List<String> _parseCsvLine(String line) {
    List<String> result = [];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current.trim());
    return result;
  }

  // ---------------- Load Constellation Lines From JSON ---------------------

  Future<Map<String, List<List<String>>>> loadConstellationLines() async {
    try {
      final jsonString = await rootBundle.loadString('assets/constellation_lines.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final Map<String, List<List<String>>> lines = {};
      
      data.forEach((constellation, rawLines) {
        if (rawLines is List) {
          final parsedLines = <List<String>>[];
          for (final rawLine in rawLines) {
            if (rawLine is List) {
              final stringLine = rawLine.map((e) => e.toString()).toList();
              parsedLines.add(List<String>.from(stringLine));
            }
          }
          lines[constellation] = parsedLines;
        }
      });
      
      return lines;
    } catch (e) {
      print('⚠️ Constellation lines failed: $e, using painter lines only');
      return {}; // Empty map = no crash
    }
  }

  // ------------------- Group Stars into Constellations ---------------------
  
  List<CelestialObject> _groupStarsByConstellation(
    List<CelestialObject> stars,
    Map<String, List<List<String>>> lines,
  ) {
    final result = <CelestialObject>[];
    
    final conData = {
      'ori': lines['ori']!,
      'uma': lines['uma']!,
      'cas': lines['cas']!,
      'leo': lines['leo']!,
      'cyg': lines['cyg']!,
      'gem': lines['gem']!,
    };
    
    // Full names
    final fullNames = {
      'ori': 'ORION',
      'uma': 'URSA MAJOR',
      'cas': 'CASSIOPEIA', 
      'leo': 'LEO',
      'cyg': 'CYGNUS',
      'gem': 'GEMINI',
    };
    
    for (final entry in conData.entries) {
      final conAbbr = entry.key.toUpperCase();
      final conName = fullNames[entry.key] ?? conAbbr;  // Full or abbr
      final conLines = entry.value;
      
      final Set<String> starNames = {};
      for (final line in conLines) {
        starNames.add(line[0]);
        if (line.length > 1) starNames.add(line[1]);
      }
      
      double totalAz = 0, totalAlt = 0;
      int count = 0;
      for (final starName in starNames) {
        final star = stars.firstWhereOrNull((s) => 
          s.name.toLowerCase().contains(starName.toLowerCase()));
        if (star != null && star.altitude > -50) {
          totalAz += star.azimuth;
          totalAlt += star.altitude;
          count++;
        }
      }
      
      if (count > 0) {
        final avgAz = totalAz / count;
        final avgAlt = totalAlt / count;
        
        result.add(CelestialObject(
          id: 'constellation_$conAbbr',
          name: conName,  // "Orion" not "ORI"
          type: 'constellation',
          azimuth: avgAz,
          altitude: avgAlt,
          description: '$conName constellation',
        ));
      }
    }
    return result;
  }
}

