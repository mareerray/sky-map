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
  static Offset toScreen(double azimuth, double altitude, Size size, double phoneAzimuth, double phoneAltitude) {
    // Key: relativeAzimuth = object azimuth MINUS phone azimuth
    final double relativeAz = ((azimuth - phoneAzimuth) + 360) % 360;
    
    final double horizonY = size.height - 150;
    final double x = (relativeAz / 360) * size.width;        // ← uses relativeAz!
    final double y = horizonY - (altitude / 90) * horizonY;
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
// --------------- Draw Constellation Lines from JSON ------------

void _drawConstellationLines(Canvas canvas, Size size) {
  // print('🔍 Drawing ${constellationLines.length} JSON constellations...');

  final linePaint = Paint()
    ..color = const Color(0xFFCDA882) 
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
    // ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5);

  int drawnLines = 0;

  // Loop your 6 constellations: ori, uma, cas, leo, cyg, gem
  for (final conEntry in constellationLines.entries) {
    final conId = conEntry.key.toLowerCase();  // 'ori', 'uma' etc.
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
      // final star1 = objects.firstWhereOrNull((obj) => 
      //   obj.name.toLowerCase().contains(star1Name.replaceAll('_', '')) || 
      //   star1Name.contains(obj.name.toLowerCase()) &&
      //   obj.altitude > 0 && obj.altitude < 90);

      // final star2 = objects.firstWhereOrNull((obj) => 
      //   obj.name.toLowerCase().contains(star2Name.replaceAll('_', '')) || 
      //   star2Name.contains(obj.name.toLowerCase()) &&
      //   obj.altitude > 0 && obj.altitude < 90);

      if (star1 != null && star2 != null) {
        print('STAR1 ${star1.name} az=${star1.azimuth} alt=${star1.altitude}');  // 🆕 ADD
        print('STAR2 ${star2.name} az=${star2.azimuth} alt=${star2.altitude}');  // 🆕 ADD
        final pos1 = toScreen(star1.azimuth, star1.altitude, size, phoneAzimuth, phoneAltitude);
        final pos2 = toScreen(star2.azimuth, star2.altitude, size, phoneAzimuth, phoneAltitude);

        print('📍 ${conId.toUpperCase()}: ${star1.name}-${star2.name}');
        print('📍  x=${pos1.dx.toStringAsFixed(0)},${pos1.dy.toStringAsFixed(0)} → ${pos2.dx.toStringAsFixed(0)},${pos2.dy.toStringAsFixed(0)}');

        canvas.drawLine(pos1, pos2, linePaint);
        drawnLines++;
      }
    }
  }
  print('✅ Drew $drawnLines lines from JSON');
}

//  void _drawConstellationLines(Canvas canvas, Size size) {
//   print('🔍 Searching for constellation lines...');
//   final starNames = objects
//       .where((obj) => obj.type == 'star' || obj.type == 'bright_star')
//       .map((obj) => obj.name.toLowerCase())
//       .toList();
//   print('⭐ Available stars: $starNames');

//   final linePaint = Paint()
//     ..color = const Color(0xFFCDA882).withValues(alpha:0.8)
//     ..strokeWidth = 1.0
//     ..style = PaintingStyle.stroke;

//   final constellationLines = [
//     ['betelgeuse', 'bellatrix'],
//     ['bellatrix', 'rigel'],
//     ['rigel', 'saiph'],
//     ['dubhe', 'merak'],
//     ['merak', 'phecda'],
//     ['caph', 'schedar'],
//   ];

//   int drawnLines = 0;
//   for (final line in constellationLines) {

//     final star1 = objects.firstWhereOrNull((obj) => 
//       obj.name.toLowerCase() == line[0].toLowerCase() && obj.altitude > 0 && obj.altitude < 90);
//     final star2 = objects.firstWhereOrNull((obj) => 
//       obj.name.toLowerCase() == line[1].toLowerCase() && obj.altitude > 0 && obj.altitude < 90);


//     if (star1 != null && star2 != null) {
//       final pos1 = toScreen(star1.azimuth, star1.altitude, size, phoneAzimuth, phoneAltitude);
//       final pos2 = toScreen(star2.azimuth, star2.altitude, size, phoneAzimuth, phoneAltitude);

//       print('📍 ${star1.name}: x=${pos1.dx.toStringAsFixed(0)} y=${pos1.dy.toStringAsFixed(0)}');
//       print('📍 ${star2.name}: x=${pos2.dx.toStringAsFixed(0)} y=${pos2.dy.toStringAsFixed(0)}');

//       canvas.drawLine(pos1, pos2, linePaint);
//       drawnLines++;
//       print('✅ LINE: ${star1.name}-${star2.name}(${drawnLines})');
//     }
//   }
// }

  // --------------- Draw Celestial Objects ------------

  void _drawObjects(Canvas canvas, Size size) {
    for (final obj in objects) {
      if (obj.altitude < -30) continue;  // DEBUGGGGGG ✅

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
