import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';

class SkyPainter extends CustomPainter {
  final List<CelestialObject> objects;
  final CelestialObject? selectedObject;
  final Map<String, List<List<String>>> constellationLines; 
  final Map<String, ui.Image> planetImages;

  final double phoneAzimuth;
  final double phoneAltitude;
  static const double fov = 120.0;

  // static int _paintCount = 0;
  // static DateTime _lastFpsTime = DateTime.now();

  SkyPainter({
    required this.objects, 
    this.selectedObject, 
    this.constellationLines = const {},
    this.phoneAzimuth = 180, 
    this.phoneAltitude = 45,
    this.planetImages = const {},  
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

    final double y = (0.5 - deltaAlt / fov) * size.height;

    return Offset(x, y);
  }

  // --------------- PAINTING LOGIC ----------------------------

  @override
  void paint(Canvas canvas, Size size) {
    // _paintCount++;

    // final now = DateTime.now();
    // final elapsedMs = now.difference(_lastFpsTime).inMilliseconds;

    // if (elapsedMs >= 1000) {
    //   final fps = _paintCount * 1000 / elapsedMs;
    //   debugPrint('SkyPainter FPS: ${fps.toStringAsFixed(1)}');

    //   _paintCount = 0;
    //   _lastFpsTime = now;
    // }

    _drawBackground(canvas, size); // 1. Draw sky + ground
    _drawHorizon(canvas, size); // 2. Horizon line
    _drawConstellationLines(canvas, size); // 3. Lines between stars
    _drawObjects(canvas, size); // 4. Stars, planets, sun
    _drawConstellationLabels(canvas, size); // 5. Name labels on top
    _drawCompass(canvas, size); // 6. Compass always on top
  }

  // --------------- Draw Background ------------

  void _drawBackground(Canvas canvas, Size size) {
    final double horizonY = (0.5 + phoneAltitude / fov) * size.height;

    // ☀️ SKY — true deep space black → rich twilight at horizon
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF000000),  // Pure black (space)
        Color(0xFF04020F),  // Almost black with hint of purple
        Color(0xFF120836),  // Deep twilight indigo
        Color(0xFF2D1158),  // Rich purple — horizon glow
        Color(0xFF4A1870),  // Vivid deep violet right at horizon
      ],
      stops: const [0.0, 0.15, 0.45, 0.78, 1.0],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // 🌍 GROUND — mirror the violet, then drop into pure darkness
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF3D1260),  // Matches sky horizon — seamless join
        Color(0xFF1A0A35),  // Deep earth purple
        Color(0xFF080510),  // Almost black
        Color(0xFF020104),  // Pure underground darkness
      ],
      stops: const [0.0, 0.25, 0.60, 1.0],
    );

    final groundPaint = Paint()
      ..shader = groundGradient.createShader(
          Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawRect(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
        groundPaint);

    // Dark overlay on ground only 
    final darkOverlayPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.45); 

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      darkOverlayPaint);
  }

  // --------------- Draw Horizon ------------

  void _drawHorizon(Canvas canvas, Size size) {
    final double horizonY = (0.5 + phoneAltitude / fov) * size.height;

    // Soft glowing horizon line 
    final glowLinePaint = Paint()
      ..color = const Color(0x55A050FF) 
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawLine(
        Offset(0, horizonY), Offset(size.width, horizonY), glowLinePaint);

    // HORIZON label 
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'HORIZON',
        style: TextStyle(
          color: Color(0x66BB88FF), 
          fontSize: 10,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(12, horizonY + 5));
  }

  // --------------- Draw Constellation Lines from JSON ------------

  void _drawConstellationLines(Canvas canvas, Size size) {
    // Build star map for quick lookup of star positions by name
    final starMap = <String, CelestialObject>{};
    for (final obj in objects) {
      if (obj.type == 'star') {
        starMap[obj.name.toLowerCase()] = obj;
      }
    }

    // Draw lines from pre-resolved constellation objects
    for (final obj in objects) {
      if (obj.type != 'constellation') continue;

      for (final pair in (obj.lines ?? [])) {
        if (pair.length < 2) continue;

        final starA = starMap[pair[0]];
        final starB = starMap[pair[1]];
        if (starA == null || starB == null) continue;

        final pos1 = toScreen(
          starA.azimuth, starA.altitude, size, phoneAzimuth, phoneAltitude
        );
        final pos2 = toScreen(
          starB.azimuth, starB.altitude, size, phoneAzimuth, phoneAltitude
        );

        if (pos1 != null && pos2 != null) {
          final opacityA = _altitudeOpacity(starA.altitude);
          final opacityB = _altitudeOpacity(starB.altitude);
          final lineOpacity = opacityA < opacityB ? opacityA : opacityB;

          final linePaint = Paint()
            ..color = const Color(0xFFCDA882).withValues(alpha: lineOpacity * 0.5)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

          canvas.drawLine(pos1, pos2, linePaint);
        }
      }
    }
  }

  // --------------- Draw Celestial Objects ------------

  void _drawObjects(Canvas canvas, Size size) {

    for (final obj in objects) {
      final offset = toScreen(obj.azimuth, obj.altitude, size, phoneAzimuth, phoneAltitude);
      if (offset == null) continue; 

      // Fade objects below horizon
      final double opacity = _altitudeOpacity(obj.altitude);

      // PLANET GLOW FIRST (behind main object)
      final double dotSize = SkyUtils.sizeForType(obj.type, magnitude: obj.magnitude ?? 3.0);
      if (obj.type == 'moon' || obj.type == 'sun' ||
          (obj.type == 'planet') ||
          (obj.type == 'star' && (obj.magnitude ?? 99) < 2.0)) {
        final glowPaint = Paint()
          ..color = SkyUtils.colorForType(obj.type).withValues(alpha: 0.25 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotSize * 1.5);
        canvas.drawCircle(offset, dotSize * 2.5, glowPaint);
      }

      // Body of object (star shape or planet image)
      final Paint paint = Paint()
        ..color = SkyUtils.colorForType(obj.type).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Stars get pointy shape, others stay circle
      if (obj.type == 'star') {
        final starPath = SkyUtils.starPath(offset, dotSize);
        canvas.drawPath(starPath, paint);
      } else if (obj.type == 'sun' || obj.type == 'planet' || obj.type == 'dwarf_planet' || obj.type == 'moon') {
        final key = obj.name.toLowerCase(); // 'sun', 'saturn', 'mars' etc.
        final img = planetImages[key];

        if (img != null) {
          final double size = dotSize * 3;
          final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
          final dst = Rect.fromCenter(center: offset, width: size, height: size);
          final imgPaint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
          canvas.drawImageRect(img, src, dst, imgPaint);
        } else {
          canvas.drawCircle(offset, dotSize, paint); // fallback if image missing
        }
      } else if (obj.type != 'constellation') {
        canvas.drawCircle(offset, dotSize, paint);  
      }

      // Name labels
      final bool alwaysShowLabel = obj.type == 'sun'         ||
                                  obj.type == 'moon'         ||
                                  obj.type == 'planet'       ||
                                  obj.type == 'dwarf_planet';
      
      final bool isSelected = selectedObject != null && selectedObject!.id == obj.id;

      if (alwaysShowLabel) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: obj.name,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: isSelected ? 1.0 : opacity * 0.7),
              fontSize: isSelected ? 15 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
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

  // Make objects below horizon fade out
  double _altitudeOpacity(double altitudeDeg) {
    if (altitudeDeg >= 0) return 1.0;        // fully visible above horizon
    if (altitudeDeg <= -20) return 0.35;     // very faint deep underground
    return 1.0 + (altitudeDeg / 20.0) * 0.65;
  }

  // --------------- Draw Constellation labels ------------

  void _drawConstellationLabels(Canvas canvas, Size size) {
    final labelStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFCDA882),
      letterSpacing: 0.6,
    );

    for (final obj in objects) {
      if (obj.type != 'constellation') continue;

      final offset = toScreen(
        obj.azimuth,
        obj.altitude,
        size,
        phoneAzimuth,
        phoneAltitude,
      );

      if (offset == null) continue;

      final textPainter = TextPainter(
        text: TextSpan(text: obj.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          offset.dx - textPainter.width / 2,
          offset.dy - textPainter.height - 4, // above the constellation center
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

      // Pin to top of screen
      final double x = (dAz / fov + 0.5) * size.width;
      const double y = 40.0; 

      final isNorth = entry.key == 'N';

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: GoogleFonts.poppins(
            color: isNorth ? Colors.red : Color(0xFF4FC3F7),
            fontSize: isNorth ? 18 : 14,
            fontWeight: isNorth ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw a small tick mark
      final tickPaint = Paint()
        ..color = isNorth ? Colors.red : Color(0xFF4FC3F7)
        ..strokeWidth = isNorth ? 3 : 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, 0), Offset(x, 20), tickPaint);

      // Draw the label
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2, 
          y - textPainter.height),
      );
    }
  }

  // --------------- Repaint Logic ------------
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = oldDelegate as SkyPainter;
    return old.phoneAzimuth != phoneAzimuth ||  // phone rotation changed
      old.phoneAltitude != phoneAltitude ||     // phone tilt changed
      old.selectedObject != selectedObject ||   // tap selection changed
      old.constellationLines != constellationLines; // lines changed
  }
}

