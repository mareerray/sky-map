class CelestialObject {
  final String id;          // Unique identifier e.g. "mars"
  final String name;        // Display name e.g. "Mars"
  final String type;        // Category: "planet", "star", "moon", "constellation"
  final String description; // Short text shown when user taps the object
  final double azimuth;     // Compass direction in degrees (0°-360°)
  final double altitude;    // Height above horizon in degrees (-90° to +90°)
  final double? magnitude;  // Brightness in the sky (lower = brighter, optional)
  final List<Map<String, dynamic>>? stars;
  final List<List<String>>? lines;

  CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.azimuth,
    required this.altitude,
    this.magnitude,
    this.stars,
    this.lines,
  });

  factory CelestialObject.fromJson(Map<String, dynamic> json) {
    return CelestialObject(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      azimuth: (json['azimuth'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      magnitude: json['magnitude'] != null
          ? (json['magnitude'] as num).toDouble()
          : null,
      stars: json['stars'] != null
          ? List<Map<String, dynamic>>.from(json['stars'])
          : null,
      lines: json['lines'] != null
          ? List<List<String>>.from(json['lines'].map((line) => List<String>.from(line)))
          : null,
    );
  }
}
