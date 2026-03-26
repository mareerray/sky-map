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
    _drawBackground(canvas, size);
    _drawHorizon(canvas, size);
    _drawConstellationLines(canvas, size);
    _drawObjects(canvas, size);
    _drawCompass(canvas, size);
  }

    // --------------- Draw Background ------------
  void _drawBackground(Canvas canvas, Size size) {
    // Dynamic horizon (0° = horizon line)
    final double horizonY = (0.5 + phoneAltitude / 60.0) * size.height;
    
    // Sky gradient (always top to horizon)
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [Color(0xFF02040F), Color(0xFF0a0a1e)], // space → horizon edge
    );

    // DARKER gradient ground — from horizon to bottom
    final groundGradient = LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0a0a1e),  // Very dark blue at horizon
        Color(0xFF08101a),  // Darker blue 
        Color(0xFF000000),  // Pure black bottom
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    // Sky: top → horizon
    final skyPaint = Paint()
      ..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // Ground: horizon → bottom (covers all negative alt objects)
    final groundPaint = Paint()
      ..shader = groundGradient.createShader(Rect.fromLTWH(0, horizonY, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, horizonY, size.width, size.height), groundPaint);
  }

  // --------------- Draw Horizon ------------

  void _drawHorizon(Canvas canvas, Size size) {
    final double horizonY = (0.5 + phoneAltitude / fov) * size.height; // moves with tilt
    
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), linePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'HORIZON',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(10, horizonY + 4));
  }

  // --------------- Draw Constellation Lines from JSON ------------

  void _drawConstellationLines(Canvas canvas, Size size) {
    // print('🔍 Drawing ${constellationLines.length} JSON constellations...');

    final linePaint = Paint()
      ..color = const Color(0xFFCDA882) 
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);

    int drawnLines = 0;

    // Loop your 6 constellations: ori, uma, cas, leo, cyg, gem
    for (final conEntry in constellationLines.entries) {
      // final conId = conEntry.key.toLowerCase();  // 'ori', 'uma' etc.
      final lines = conEntry.value;

      for (final line in lines) {
        if (line.length < 2) continue;

        final star1Name = line[0].toString().toLowerCase();
        final star2Name = line[1].toString().toLowerCase();

        // Flexible name match (handles gamma_cas → cih)
        final star1 = objects.firstWhereOrNull((obj) => 
          obj.name.toLowerCase() == star1Name && obj.altitude > 0);
        final star2 = objects.firstWhereOrNull((obj) => 
          obj.name.toLowerCase() == star2Name && obj.altitude > 0);

        if (star1 != null && star2 != null) {
          final pos1 = toScreen(star1.azimuth, star1.altitude, size, phoneAzimuth, phoneAltitude);
          final pos2 = toScreen(star2.azimuth, star2.altitude, size, phoneAzimuth, phoneAltitude);
          // print('LINE ${star1.name}-${star2.name}: ${pos1.dx.toInt()},${pos1.dy.toInt()} → ${pos2.dx.toInt()},${pos2.dy.toInt()}');

          if (pos1 == null || pos2 == null) continue;
          canvas.drawLine(pos1, pos2, linePaint);
          drawnLines++;
        }
      }
    }
  }

  // --------------- Draw Celestial Objects ------------

  void _drawObjects(Canvas canvas, Size size) {
    for (final obj in objects) {
      // if (obj.type != 'constellation' && obj.altitude < -90) continue;  

      final offset = toScreen(obj.azimuth, obj.altitude, size, phoneAzimuth, phoneAltitude);
      if (offset == null) continue; 

      // 🎇 PLANET GLOW FIRST (behind main dot)
      final double dotSize = SkyUtils.sizeForType(obj.type, magnitude: obj.magnitude ?? 1.0);
      if (obj.type == 'moon' || (obj.type == 'planet' && (obj.magnitude ?? 1.0) < 2.0)) {
        final glowPaint = Paint()
          ..color = SkyUtils.colorForType(obj.type).withValues(alpha:0.3)  
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(offset, dotSize * 2, glowPaint);  
      }

      // ⭐ MAIN DOT
      final Paint paint = Paint()
        ..color = SkyUtils.colorForType(obj.type)
        ..style = PaintingStyle.fill;
      // Stars get pointy shape, others stay circle
      if (obj.type == 'bright_star' || obj.type == 'star') {
        final starPath = SkyUtils.starPath(offset, dotSize);
        canvas.drawPath(starPath, paint);
      } else {
        canvas.drawCircle(offset, dotSize, paint);  // Planets/moon stay round
      }
      // canvas.drawCircle(offset, SkyUtils.sizeForType(obj.type, magnitude: obj.magnitude ?? 1.0), paint);

      // 🏷️ LABELS (planets/constellations always, others when selected)
      final bool alwaysShowLabel = obj.type == 'sun'         ||
                                  obj.type == 'moon'         ||
                                  obj.type == 'planet'       ||
                                  obj.type == 'dwarf_planet' ||
                                  obj.type == 'constellation'; // ← add this

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
            color: isNorth ? Colors.red : Colors.white70,
            fontSize: isNorth ? 18 : 13,
            fontWeight: isNorth ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw a small tick mark
      final tickPaint = Paint()
        ..color = isNorth ? Colors.red : Colors.white38
        ..strokeWidth = isNorth ? 2 : 1;
      canvas.drawLine(Offset(x, 0), Offset(x, 20), tickPaint);

      // Draw the label
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

