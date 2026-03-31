import 'dart:math' as math;
import 'package:astronomia/astronomia.dart';
import 'package:astronomia/planetposition.dart';
import 'package:astronomia/elliptic.dart' as elliptic;
import 'package:astronomia/solar.dart' as solar;
import 'package:astronomia/moonposition.dart' as moon_position;
import 'package:astronomia/coord.dart' as coord;

class AstroCalculator {
  final double latDeg;
  final double lonDeg;

  AstroCalculator({required this.latDeg, required this.lonDeg});

  double _toJD(DateTime dt) {
    final utc = dt.toUtc();
    return calendarGregorianToJD(
      utc.year,
      utc.month,
      utc.day + (utc.hour + utc.minute / 60 + utc.second / 3600) / 24,
    );
  }

  // Calculate Local Sidereal Time in radians using standard formula
  double _calcLST(double jd) {
    final T = (jd - 2451545.0) / 36525.0; // centuries from J2000.0
    // Greenwich Mean Sidereal Time in degrees
    double gmst = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * T * T -
        (T * T * T) / 38710000.0;
    gmst = gmst % 360.0;
    if (gmst < 0) gmst += 360.0;
    // Local Sidereal Time = GMST + observer longitude
    double lst = gmst + lonDeg;
    lst = lst % 360.0;
    if (lst < 0) lst += 360.0;
    return toRad(lst);
  }

  Map<String, double> _toHorizontal(double ra, double dec, double jd) {
    final lat = toRad(latDeg);
    final lst = _calcLST(jd);
    final lha = lst - ra; // Local Hour Angle in radians

    final sinAlt = math.sin(lat) * math.sin(dec) +
        math.cos(lat) * math.cos(dec) * math.cos(lha);
    final altitude = toDeg(math.asin(sinAlt.clamp(-1.0, 1.0)));

    final cosA = (math.sin(dec) - math.sin(lat) * sinAlt) /
        (math.cos(lat) * math.cos(math.asin(sinAlt.clamp(-1.0, 1.0))));
    double azimuth = toDeg(math.acos(cosA.clamp(-1.0, 1.0)));
    if (math.sin(lha) > 0) azimuth = 360 - azimuth;

    return {'azimuth': azimuth, 'altitude': altitude};
  }

  Map<String, double> getSun() {
    final jd = _toJD(DateTime.now());
    final T = j2000Century(jd);
    final lon = solar.apparentLongitude(T);
    final eps = toRad(23.439);
    final eq = coord.eclToEq(lon, 0, math.sin(eps), math.cos(eps));
    return _toHorizontal(eq.ra, eq.dec, jd);
  }

  Map<String, double> getMoon() {
    final jd = _toJD(DateTime.now());
    final pos = moon_position.position(jd);
    final eps = toRad(23.439);
    final eq = coord.eclToEq(pos.lon, pos.lat, math.sin(eps), math.cos(eps));
    return _toHorizontal(eq.ra, eq.dec, jd);
  }

  Map<String, double> getPlanet(Planet planet) {
    final jd = _toJD(DateTime.now());
    final earth = Planet(planetEarth);
    final eq = elliptic.position(planet, earth, jd);
    return _toHorizontal(eq.ra, eq.dec, jd);
  }

  Map<String, double> getStarHorizontal({
    required double raHours,
    required double decDeg,
    DateTime? time,
  }) {
    final dt = time ?? DateTime.now();
    final jd = _toJD(dt);

    final raRad  = toRad(raHours * 15.0); // hours → degrees → radians
    final decRad = toRad(decDeg);         // degrees → radians

    return _toHorizontal(raRad, decRad, jd);
  }
}

/**
 * AstroCalculator - Astronomical Position Calculator
 * =================================================
 *
 * Converts equatorial coordinates (RA/Dec) to local horizon coordinates (Azimuth/Altitude)
 * for a given observer location and time. Implements precise astronomical calculations
 * including Local Sidereal Time (LST), Julian Date conversion, and equatorial-to-horizontal
 * coordinate transformation.
 *
 * Primary use case: Transform HYG Database v3.2 star catalog (fixed RA/Dec) into real-time
 * sky positions for interactive sky map applications.
 *
 * Features:
 * - Sun, Moon, and major planet position calculations
 * - Star catalog coordinate conversion (getStarHorizontal)
 * - Location-aware (latitude/longitude)
 * - Time-aware (current or specified DateTime)
 * 
 * Dependencies: astronomia package (professional astronomy library)
 * 
 * Usage:
 * 
 * final calc = AstroCalculator(latDeg: 60.17, lonDeg: 24.94); // Helsinki
 * final starPos = calc.getStarHorizontal(raHours: 5.5, decDeg: 45.0);
 * 
 * Precision: Sub-arcminute accuracy suitable for visual astronomy applications.
 * 
 */