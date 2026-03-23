// GPS → AstronomyAPI → constellations + background stars → done ✅
import 'dart:convert';

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
    print('📍 GPS: lat=${position.latitude}, lon=${position.longitude}');

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

    return [...realObjects, ...groupedObjects, ...starObjects];
  }

  // --------------------- Load Stars from CSV ---------------------

  Future<List<CelestialObject>> _loadStarsFromCsv(AstroCalculator astro) async {
    final rawCsv = await rootBundle.loadString('assets/hygdata_v42.csv');
    final lines = rawCsv.split('\n');

    final List<CelestialObject> stars = [];
    int processed = 0;

    for (int i = 1; i < lines.length && processed < 50000; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || !line.contains(',')) continue;

      try {
        final row = _parseCsvLine(line);
        
        // ✅ Exact column indexes from the header we saw
        final con = row[29].trim().toLowerCase();  // "con"
        final mag = double.tryParse(row[13].trim()) ?? 99.0;  // "mag"
        final raDeg   = double.tryParse(row[17].trim()) ?? 0.0;  // 🆕 ra DEGREES col 17!
        final decDeg  = double.tryParse(row[19].trim()) ?? 0.0;  // dec col 18 ✅   
        final name    = row[6].trim();  // "proper"

        if (!_constellations.contains(con)) continue;

        // 🆕 Tiered brightness filtering
        if (mag > 3.0) continue; // Only stars brighter than mag 3.0

        String starType = 'star';
        if (mag <= 1.5) {
          starType = 'bright_star'; // Very bright
        } else if (mag <= 2.5) {
          starType = 'star'; // Normal stars
        }   

        final coords = astro.getStarHorizontal(raHours: raDeg / 15.0, decDeg: decDeg);
        print('DEBUG $name az=${coords['azimuth']} alt=${coords['altitude']}');

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

    print('⭐ Loaded ${stars.length} constellation stars from CSV');
    return stars;
  }

  // Helper method for proper CSV parsing
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
      
      print('📊 Loaded ${lines.length} constellations with lines');
      return lines;
    } catch (e) {
      print('⚠️ Constellation lines failed: $e, using painter lines only');
      return {}; // Empty map = no crash
    }
  }

  List<CelestialObject> _groupStarsByConstellation(
    List<CelestialObject> stars,
    Map<String, List<List<String>>> lines,
  ) {
    final Map<String, List<CelestialObject>> groups = {};
    
    for (final star in stars) {
      final con = star.name.toLowerCase(); // e.g. "betelgeuse" or "ori"
      if (!groups.containsKey(con)) groups[con] = [];
      groups[con]!.add(star);
    }

    final result = <CelestialObject>[];
    for (final entry in groups.entries) {
      final conName = entry.key.toUpperCase();
      result.add(CelestialObject(
        id: 'constellation_$conName',
        name: conName,
        type: 'constellation',
        stars: entry.value.map((star) => {
          'name': star.name,
          'azimuth': star.azimuth,
          'altitude': star.altitude,
        }).toList(), 
        lines: lines[conName.toLowerCase()] ?? [],
        azimuth: 0, altitude: 0, // dummy
        description: '$conName constellation',
      ));
    }
    return result;
  }
}

