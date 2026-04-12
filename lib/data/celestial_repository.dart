import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';
import 'astronomy_api_service.dart';
import 'astro_calculator.dart';

class CelestialRepository {
  final _api = AstronomyApiService();

  // 19 chosen constellations
  static const _constellations = {'ori', 'uma', 'cas', 'leo', 'cyg', 'gem', 'lib', 'aql', 'aqr', 'cet', 'her', 'lyr', 'dra', 'mon', 'cnc', 'and', 'peg', 'boo', 'vir', 'hya', 'lep'};

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

    // Return SkyLoaded exactly like the state expects
    return [...realObjects, ...groupedObjects, ...starObjects];
  }

  // --------------------- Load Stars from CSV file ---------------------

  Future<List<CelestialObject>> _loadStarsFromCsv(AstroCalculator astro) async {
    
    final rawCsv = await rootBundle.loadString('assets/hygdata_v42.csv');
    final lines = rawCsv.split('\n');

    // print('HEADER: ${lines[0]}');

    final List<CelestialObject> stars = [];
    const mustKeepStars = {
      'mira', // Cetus - variable star, can be dimmer than mag 6
    };
    int processed = 0;

    for (int i = 1; i < lines.length && processed < 15000; i++) {

      final line = lines[i].trim();
      if (line.isEmpty || !line.contains(',')) continue;

      try {
        final row = _parseCsvLine(line);
        
        // Exact column indexes from the header in the CSV file
        final con = row[29].trim().toLowerCase();  // "con" - constellation abbreviation
        final mag = double.tryParse(row[13].trim()) ?? 99.0;  // "mag" - magnitude (brightness)
        final raHours = double.tryParse(row[7].trim()) ?? 0.0;   // col 7 = "ra" in HOURS (0 to 24)
        final decDeg  = double.tryParse(row[8].trim()) ?? 0.0;   // col 8 = "dec" in degrees (-90 to +90)
        final name    = row[6].trim();  // "proper" - proper name (can be empty)


        if (!_constellations.contains(con)) continue;
        if (name.isEmpty) continue;  // skip stars with no proper name

        // Keep if bright enough OR if it's a required constellation line star
        final isRequired = mustKeepStars.contains(name.toLowerCase());
        if (mag > 6 && !isRequired) continue;

        final coords = astro.getStarHorizontal(raHours: raHours, decDeg: decDeg);

        final az = coords['azimuth'] ?? 0.0;
        final alt = coords['altitude'] ?? 0.0;
        final conFullName = SkyUtils.constellationNames[con] ?? con.toUpperCase();

        final nameDesc = SkyUtils.descriptionFor(name.toLowerCase());
        final description = nameDesc.isNotEmpty 
          ? nameDesc 
          : 'A star in the $conFullName constellation';

        stars.add(CelestialObject(
          id: 'star_$processed',
          name: name,
          type: 'star',
          description: description,
          azimuth: az,
          altitude: alt,
          magnitude: mag,
        ));

        processed++;
      } catch (e) {
        // Skip bad rows
      }
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
      // print('⚠️ Constellation lines failed: $e, using painter lines only');
      return {}; // Empty map = no crash
    }
  }

  // ------------------- Group Stars into Constellations ---------------------
  List<CelestialObject> _groupStarsByConstellation(
    List<CelestialObject> stars,
    Map<String, List<List<String>>> lines,
  ) {
    final result = <CelestialObject>[];

    // Build a lookup map: lowercase name → star object
    // This makes finding stars by name fast and easy
    final starMap = <String, CelestialObject>{};
    for (final star in stars) {
      starMap[star.name.toLowerCase()] = star;
    }

    final fullNames = SkyUtils.constellationNames;

    for (final conKey in _constellations) {
      final conLines = lines[conKey] ?? [];
      final conName = fullNames[conKey] ?? conKey;

      // Build resolved line pairs: each pair is two star names that EXIST in our map
      final resolvedLines = <List<String>>[];

      // Also collect star positions for center calculation
      double sumSin = 0;
      double sumCos = 0;
      double totalAlt = 0;
      int count = 0;
      final Set<String> seenStars = {};

      for (final pair in conLines) {
        if (pair.length < 2) continue;

        final nameA = pair[0].toLowerCase();
        final nameB = pair[1].toLowerCase();

        final starA = starMap[nameA];
        final starB = starMap[nameB];

        // Only draw the line if BOTH stars were found and loaded
        if (starA != null && starB != null) {
          resolvedLines.add([nameA, nameB]);

          // Add to center calculation (avoid counting same star twice)
          if (!seenStars.contains(nameA)) {
            final azRad = starA.azimuth * math.pi / 180.0;
            sumSin += math.sin(azRad);
            sumCos += math.cos(azRad);
            totalAlt += starA.altitude;
            count++;
            seenStars.add(nameA);
          }
          if (!seenStars.contains(nameB)) {
            final azRad = starB.azimuth * math.pi / 180.0;
            sumSin += math.sin(azRad);
            sumCos += math.cos(azRad);
            totalAlt += starB.altitude;
            count++;
            seenStars.add(nameB);
          }
        }
      }

      if (count > 0) {
        double avgAz = math.atan2(sumSin / count, sumCos / count) * 180.0 / math.pi;
        if (avgAz < 0) avgAz += 360;

        result.add(
          CelestialObject(
            id: 'constellation_$conKey',
            name: conName,
            type: 'constellation',
            azimuth: math.atan2(sumSin, sumCos) * 180.0 / math.pi,
            altitude: totalAlt / count,
            description: '$conName constellation',
            lines: resolvedLines,  
          )
        );
      }
    }
    return result;
  }
}

