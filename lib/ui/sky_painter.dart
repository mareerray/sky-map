import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';

class SkyPainter extends CustomPainter {
  final List<CelestialObject> objects;
  final CelestialObject? selectedObject;
  final Map<String, List<List<String>>> constellationLines; 

  final double phoneAzimuth;
  final double phoneAltitude;

  static const double fov = 60.0;

  int _lastObjectCount = 0; // ✅ Print ONCE when stars change

  SkyPainter({
    required this.objects, 
    this.selectedObject, 
    this.constellationLines = const {},
    this.phoneAzimuth = 180, 
    this.phoneAltitude = 45,
  });

  // Static method — used by both painter and sky_screen.dart
  static Offset? toScreen(
    double azimuth,
    double altitude,
    Size size,
    double phoneAzimuth,
    double phoneAltitude,
  ) {
    // Horizontal offset
    final double deltaAz = ((azimuth - phoneAzimuth) + 540) % 360 - 180;

    // Vertical offset
    final double deltaAlt = altitude - phoneAltitude;

    // Cull outside FOV
    if (deltaAz.abs() > fov / 2) return null;
    if (deltaAlt.abs() > fov / 2) return null;

    // Map to screen
    final double x = (deltaAz / fov + 0.5) * size.width;

    // IMPORTANT: if altitude increases when you tilt up,
    // then objects ABOVE where you point have deltaAlt > 0
    // they should appear ABOVE the center → y smaller.
    final double y = (0.5 - deltaAlt / fov) * size.height;

    return Offset(x, y);
  }

  // --------------- PAINTING LOGIC ----------------------------

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Print ONCE when stars change
    if (objects.isNotEmpty && _lastObjectCount != objects.length) {
      _lastObjectCount = objects.length;
    }

    _drawBackground(canvas, size); // 1. Black sky + ground
    _drawHorizon(canvas, size); // 2. Horizon line
    _drawConstellationLines(canvas, size); // 3. Lines between stars
    _drawObjects(canvas, size); // 4. Stars, planets, sun
    _drawConstellationLabels(canvas, size); // 5. Name labels on top
    _drawCompass(canvas, size); // 6. Compass always on top
  }

  // --------------- Draw Background ------------
  void _drawBackground(Canvas canvas, Size size) {
    final double horizonY = (0.5 + phoneAltitude / fov) * size.height;

    // ☀️ SKY — deep space → warm sunset glow near horizon
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF01010A),  // Deep space black
        Color(0xFF0D0B2A),  // Dark indigo
        Color(0xFF1B1040),  // Deep purple
        Color(0xFF3B1F5E),  // Purple
      ],
      stops: const [0.0, 0.30, 0.70, 1.0],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // 🌍 GROUND — warm glow at horizon fading to dark earth
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color.fromARGB(255, 47, 21, 8),  // Dark reddish-brown
        Color(0xFF1A0A05),  // Very dark earth
        Color(0xFF000000),  // Black bottom
      ],
      stops: const [0.0, 0.40, 1.0],
    );

    final groundPaint = Paint()
      ..shader = groundGradient.createShader(
          Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawRect(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
        groundPaint);
  }

  // void _drawBackground(Canvas canvas, Size size) {
  //   // Dynamic horizon (0° = horizon line)
  //   final double horizonY = (0.5 + phoneAltitude / fov) * size.height;
    
  //   // Sky gradient (always top to horizon)
  //   final skyGradient = LinearGradient(
  //     begin: Alignment.topCenter,
  //     end: Alignment.center,
  //     colors: [Color(0xFF02040F), Color(0xFF0a0a1e)], // space → horizon edge
  //   );

  //   // DARKER gradient ground — from horizon to bottom
  //   final groundGradient = LinearGradient(
  //     begin: Alignment.center,
  //     end: Alignment.bottomCenter,
  //     colors: [
  //       Color(0xFF0a0a1e),  // Very dark blue at horizon
  //       Color(0xFF08101a),  // Darker blue 
  //       Color(0xFF000000),  // Pure black bottom
  //     ],
  //     stops: const [0.0, 0.6, 1.0],
  //   );

  //   // Sky: top → horizon
  //   final skyPaint = Paint()
  //     ..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
  //   canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

  //   // Ground: horizon → bottom (covers all negative alt objects)
  //   final groundPaint = Paint()
  //     ..shader = groundGradient.createShader(Rect.fromLTWH(0, horizonY, size.width, size.height));
  //   canvas.drawRect(Rect.fromLTWH(0, horizonY, size.width, size.height), groundPaint);
  // }

  // --------------- Draw Horizon ------------
  void _drawHorizon(Canvas canvas, Size size) {
    final double horizonY = (0.5 + phoneAltitude / fov) * size.height;

    // Soft glowing horizon line
    final glowLinePaint = Paint()
      ..color = const Color(0x44FF8030)  // Orange glow
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
        Offset(0, horizonY), Offset(size.width, horizonY), glowLinePaint);

    // HORIZON label — subtle and warm toned
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'HORIZON',
        style: TextStyle(
          color: Color(0x88FFAA55),  // Warm orange, faded
          fontSize: 10,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(12, horizonY + 5));
  }
  // void _drawHorizon(Canvas canvas, Size size) {
  //   final double horizonY = (0.5 + phoneAltitude / fov) * size.height; // moves with tilt
    
  //   final linePaint = Paint()
  //     ..color = Colors.white24
  //     ..strokeWidth = 2.0;

  //   canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), linePaint);

  //   final textPainter = TextPainter(
  //     text: const TextSpan(
  //       text: 'HORIZON',
  //       style: TextStyle(color: Colors.white38, fontSize: 11),
  //     ),
  //     textDirection: TextDirection.ltr,
  //   )..layout();

  //   textPainter.paint(canvas, Offset(10, horizonY + 4));
  // }

  // --------------- Draw Constellation Lines from JSON ------------

  void _drawConstellationLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFCDA882) 
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5);

  // Build star lookup once
    final starMap = <String, CelestialObject>{};
    for (final obj in objects) {
      if (obj.type == 'star') starMap[obj.name.toLowerCase()] = obj;
    }

    // Draw lines from pre-resolved constellation objects
    for (final obj in objects) {
      if (obj.type != 'constellation') continue;
      for (final pair in (obj.lines ?? [])) {
        if (pair.length < 2) continue;
        final starA = starMap[pair[0]];
        final starB = starMap[pair[1]];
        if (starA == null || starB == null) continue;

        final pos1 = toScreen(starA.azimuth, starA.altitude, size, phoneAzimuth, phoneAltitude);
        final pos2 = toScreen(starB.azimuth, starB.altitude, size, phoneAzimuth, phoneAltitude);
        if (pos1 != null && pos2 != null) {
          canvas.drawLine(pos1, pos2, linePaint);
        }
      }
    }
  }

  // --------------- Draw Celestial Objects ------------

  void _drawObjects(Canvas canvas, Size size) {
    for (final obj in objects) {
      // if (obj.type == 'star' && 
      //   (obj.name == 'Rigel' || obj.name == 'Betelgeuse' || obj.name == 'Meissa')) {
      //   print('🎨 Drawing ${obj.name} → magnitude=${obj.magnitude}');
      // } 

      final offset = toScreen(obj.azimuth, obj.altitude, size, phoneAzimuth, phoneAltitude);
      if (offset == null) continue; 

      // 🎇 PLANET GLOW FIRST (behind main dot)
      final double dotSize = SkyUtils.sizeForType(obj.type, magnitude: obj.magnitude ?? 3.0);
      if (obj.type == 'moon' || obj.type == 'sun' ||
          (obj.type == 'planet') ||
          (obj.type == 'star' && (obj.magnitude ?? 99) < 2.0)) {
        final glowPaint = Paint()
          ..color = SkyUtils.colorForType(obj.type).withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotSize * 1.5);
        canvas.drawCircle(offset, dotSize * 2.5, glowPaint);
      }

      // ⭐ MAIN DOT
      final Paint paint = Paint()
        ..color = SkyUtils.colorForType(obj.type)
        ..style = PaintingStyle.fill;
      // Stars get pointy shape, others stay circle
      if (obj.type == 'star') {
        final starPath = SkyUtils.starPath(offset, dotSize);
        canvas.drawPath(starPath, paint);
      } else if (obj.type != 'constellation') {
        canvas.drawCircle(offset, dotSize, paint);  // Planets/moon stay round
      }

      // 🏷️ LABELS 
      final bool alwaysShowLabel = obj.type == 'sun'         ||
                                  obj.type == 'moon'         ||
                                  obj.type == 'planet'       ||
                                  obj.type == 'dwarf_planet';

      final bool isSelected = selectedObject != null && selectedObject!.id == obj.id;

      if (alwaysShowLabel || isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: obj.name,
            style: GoogleFonts.poppins(
              color: SkyUtils.colorForType(obj.type).withValues(alpha: isSelected ? 1.0 : 0.7),
              fontSize: isSelected ? 13 : 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(offset.dx - textPainter.width / 2, offset.dy + SkyUtils.sizeForType(obj.type, magnitude: obj.magnitude ?? 1.0) + 1),
        );
      }
    }
  }

  // --------------- Draw Constellation labels (optional) ------------

  void _drawConstellationLabels(Canvas canvas, Size size) {
  final labelStyle = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFCDA882),
  );

  final constName = {
    'ori': 'Orion',
    'uma': 'Ursa Major',
    'cas': 'Cassiopeia',
    'leo': 'Leo',
    'cyg': 'Cygnus',
    'gem': 'Gemini',
  };

  for (final entry in constName.entries) {
    final acronym = entry.key;
    final fullName = entry.value;

  final targetStarName = {
    'ori': 'betelgeuse',
    'uma': 'dubhe',
    'cas': 'schedar',   // brightest in Cassiopeia
    'leo': 'regulus',   // brightest in Leo
    'cyg': 'alpha cygni',     // brightest in Cygnus
    'gem': 'pollux',    // brightest in Gemini
  }[acronym];

    if (targetStarName == null) continue;

    final star = objects.firstWhereOrNull(
      (obj) => obj.name.toLowerCase().contains(targetStarName),
    );

    if (star == null) continue;

    final pos = toScreen(
      star.azimuth,
      star.altitude,
      size,
      phoneAzimuth,
      phoneAltitude,
    );

    if (pos == null) continue;

    final textPainter = TextPainter(
      text: TextSpan(text: fullName, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height,
      ),
    );
  }
}

  // --------------- Draw Compass ------------

  void _drawCompass(Canvas canvas, Size size) {
    final directions = {
      'N': 0.0,
      'NE': 45.0,
      'E': 90.0,
      'SE': 135.0,
      'S': 180.0,
      'SW': 225.0,
      'W': 270.0,
      'NW': 315.0,
    };

    for (final entry in directions.entries) {
      // final double dAz = ((phoneAzimuth - entry.value) + 540) % 360 - 180;
      final double dAz = ((entry.value - phoneAzimuth) + 540) % 360 - 180;

      // Only show if within field of view
      if (dAz.abs() > fov / 2) continue;

      // Pin to bottom of screen
      final double x = (dAz / fov + 0.5) * size.width;
      const double y = 40.0; // ← fixed at top of screen

      final isNorth = entry.key == 'N';

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: GoogleFonts.poppins(
            color: isNorth ? Colors.red : Color(0xFF4FC3F7),
            fontSize: isNorth ? 18 : 13,
            fontWeight: isNorth ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw a small tick mark
      final tickPaint = Paint()
        ..color = isNorth ? Colors.red : Color(0xFF4FC3F7)
        ..strokeWidth = isNorth ? 3 : 2;
      canvas.drawLine(Offset(x, 0), Offset(x, 20), tickPaint);

      // Draw the label
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = oldDelegate as SkyPainter;
    return old.phoneAzimuth != phoneAzimuth ||
      old.phoneAltitude != phoneAltitude ||
      old.objects != objects ||
      old.selectedObject != selectedObject ||
      old.constellationLines != constellationLines;
  }
}

