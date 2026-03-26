import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/celestial_object.dart';
import '../utils/sky_utils.dart';

class AstronomyApiService {
  String get _appId     => dotenv.env['ASTRONOMY_APP_ID']     ?? '';
  String get _appSecret => dotenv.env['ASTRONOMY_APP_SECRET'] ?? '';
  static const String _baseUrl   = 'https://api.astronomyapi.com/api/v2';

  String get _authHeader {
    // print('🔑 AppId loaded: ${_appId.isNotEmpty ? "YES" : "NO - KEY MISSING!"}');
    final credentials = '$_appId:$_appSecret';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  Future<List<CelestialObject>> fetchBodies({
    required double latitude,
    required double longitude,
    required double elevation,
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
    // print('🌙 API Moon: ${data['data']['table']['rows'].where((r) => r['entry']['id'] == 'moon').map((r) => {
    //   'az': r['cells'][0]['position']['horizontal']['azimuth']['degrees'],
    //   'alt': r['cells'][0]['position']['horizontal']['altitude']['degrees']
    // }).toList()}');

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
        type:        SkyUtils.typeFor(id),
        description: SkyUtils.descriptionFor(id),
        azimuth:     azimuth,
        altitude:    altitude,
        magnitude:   magnitude != null
            ? double.tryParse(magnitude.toString())
            : null,
        ));
      } 

      final timestamp = now.toLocal().toString().split('.')[0];  // e.g. "2026-03-26 15:08:45"
      print('\x1b[36m🌟 API Objects (${result.length}) [$timestamp]:\x1b[0m');
      for (final obj in result) {
        print('\x1b[36m  ${obj.name.padRight(12)} az:${obj.azimuth.toStringAsFixed(0).padRight(5)} alt:${obj.altitude.toStringAsFixed(0).padRight(4)} (mag:${obj.magnitude?.toStringAsFixed(1) ?? "--"})\x1b[0m');
      }
      print('');

    return result;
  }

}
