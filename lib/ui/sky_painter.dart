import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';

class SkyPainter extends CustomPainter {
  final List<CelestialObject> objects;
  final CelestialObject? selectedObject;

  final double phoneAzimuth;
  final double phoneAltitude;

  static const double fov = 60.0;

  SkyPainter({
    required this.objects, 
    this.selectedObject, 
    this.phoneAzimuth = 180, 
    this.phoneAltitude = 45,
  });

  // Static method — used by both painter and sky_screen.dart
  static Offset toScreen(double azimuth, double altitude, Size size, double phoneAzimuth, double phoneAltitude) {
    // Key: relativeAzimuth = object azimuth MINUS phone azimuth
    final double relativeAz = ((azimuth - phoneAzimuth) + 360) % 360;
    
    final double horizonY = size.height - 150;
    final double x = (relativeAz / 360) * size.width;        // ← uses relativeAz!
    final double y = horizonY - (altitude / 90) * horizonY;
    return Offset(x, y);
  }

  // static Offset toScreen(double azimuth, double altitude, Size size, double phoneAzimuth, double phoneAltitude) {
  //   final double horizonY = size.height - 150;
  //   final double x = (azimuth / 360) * size.width;
  //   final double y = horizonY - (altitude / 90) * horizonY;
  //   return Offset(x, y);
  // }

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
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000000),
          Color(0xFF000510),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // --------------- Draw Horizon ------------

  void _drawHorizon(Canvas canvas, Size size) {
    final double horizonY = size.height - 120; // ← match the same value
    
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

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

  // --------------- Draw Constellation Lines ------------

  void _drawConstellationLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Color(0xFF5C6BC0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final obj in objects) {
      if (obj.altitude < 0) continue;
      if (obj.type != 'constellation' || obj.stars == null || obj.stars!.isEmpty) {
        continue;
      }

      // Build a map of star name → screen position
      final Map<String, Offset> starPositions = {};
      for (final star in obj.stars!) {
        final name = star['name'] as String;
        starPositions[name] = toScreen(
          (star['azimuth'] as num).toDouble(),
          (star['altitude'] as num).toDouble(),
          size, 
          phoneAzimuth,
          phoneAltitude
        );
      }

      // Draw lines using the connections defined in JSON
      final lines = obj.lines; // you'll need to add this to your model
      if (lines == null) continue;

      for (final line in lines) {
        final from = starPositions[line[0]];
        final to = starPositions[line[1]];
        if (from != null && to != null) {
          canvas.drawLine(from, to, linePaint);
        }
      }
    }
  }

  // --------------- Draw Celestial Objects ------------

  void _drawObjects(Canvas canvas, Size size) {
    for (final obj in objects) {
      if (obj.altitude < 0) continue;

      final offset = toScreen(obj.azimuth, obj.altitude, size, phoneAzimuth, phoneAltitude);

      final Paint paint = Paint()
        ..color = SkyUtils.colorForType(obj.type)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, SkyUtils.sizeForType(obj.type), paint);

      final bool alwaysShowLabel = obj.type == 'star'         ||
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
          Offset(offset.dx - textPainter.width / 2, offset.dy + SkyUtils.sizeForType(obj.type) + 1),
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
