import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/celestial_object.dart';

class AstronomyApiService {
  static const String _appId     = '416bacb7-6118-41e7-901c-876cff2843a2';
  static const String _appSecret = '915111f195cfb46f3d94f0d22f5cd798f771b5a248e416355967b0ee877c4e4f45e1e6c74559baa18f087a138ee76750bb4dc0c9698a383c370dfb36f0c7b425a9c9f9d30a8ca1b95076ec0c8b940e1d83408be829d3e6dc95deb980d102c73c19a95d757abae84c40ffd782e0cca5ad';
  static const String _baseUrl   = 'https://api.astronomyapi.com/api/v2';

  String get _authHeader {
    final credentials = '$_appId:$_appSecret';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  Future<List<CelestialObject>> fetchBodies({
    double latitude  = 60.1,
    double longitude = 19.9,
    double elevation = 10,
  }) async {
    final now  = DateTime.now().toUtc();
    final date = '${now.year}-'
        '${now.month.toString().padLeft(2,'0')}-'
        '${now.day.toString().padLeft(2,'0')}';
    final time = '${now.hour.toString().padLeft(2,'0')}:'
        '${now.minute.toString().padLeft(2,'0')}:00';

    final uri = Uri.parse('$_baseUrl/bodies/positions').replace(
      queryParameters: {
        'latitude':  latitude.toString(),
        'longitude': longitude.toString(),
        'elevation': elevation.toString(),
        'from_date': date,
        'to_date':   date,
        'time':      time,
      },
    );

    final response = await http.get(
      uri,
      headers: {HttpHeaders.authorizationHeader: _authHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} — ${response.body}');
    }

    final data = json.decode(response.body);
    final rows = data['data']['table']['rows'] as List;
    final List<CelestialObject> result = [];

    for (final row in rows) {
      final id   = (row['entry']['id']   as String).toLowerCase();
      final name =  row['entry']['name'] as String;

      if (id == 'earth') continue; // skip Earth

      // API returns multiple cells (one per date) — we only need the first
      final cell     = (row['cells'] as List).first;
      final position = cell['position']['horizontal'];
      final azimuth  = double.parse(position['azimuth']['degrees']);
      final altitude = double.parse(position['altitude']['degrees']);
      final magnitude = cell['extraInfo']['magnitude'];

      result.add(CelestialObject(
        id:          id,
        name:        name,
        type:        _typeFor(id),
        description: _descriptionFor(id),
        azimuth:     azimuth,
        altitude:    altitude,
        magnitude:   magnitude != null
            ? double.tryParse(magnitude.toString())
            : null,
      ));
    }

    return result;
  }

  String _typeFor(String id) {
    switch (id) {
      case 'sun':   return 'star';
      case 'moon':  return 'moon';
      case 'pluto': return 'dwarf_planet';
      default:      return 'planet';
    }
  }

  String _descriptionFor(String id) {
    const Map<String, String> descriptions = {
      'sun':     'The star at the center of our Solar System.',
      'moon':    'Earth\'s only natural satellite.',
      'mercury': 'The smallest planet and closest to the Sun.',
      'venus':   'The hottest planet. Brightest object in the night sky after the Moon.',
      'mars':    'The Red Planet. Has the largest volcano in the Solar System.',
      'jupiter': 'The largest planet. Has a giant storm called the Great Red Spot.',
      'saturn':  'Known for its stunning ring system made of ice and rock.',
      'uranus':  'An ice giant that rotates on its side.',
      'neptune': 'The farthest planet. Has the strongest winds in the Solar System.',
      'pluto':   'A dwarf planet in the Kuiper Belt.',
    };
    return descriptions[id] ?? '';
  }
}
