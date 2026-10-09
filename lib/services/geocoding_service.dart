import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodeResult {
  final double latitude;
  final double longitude;
  final String displayName;

  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance = GeocodingService._();

  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Looks up an address/place name and returns the best match.
  /// Returns null if nothing was found.
  ///
  /// [countryCode] optionally biases results to a specific country
  /// (e.g. 'vn'). Leave null to search globally.
  Future<GeocodeResult?> lookup(String query, {String? countryCode}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': trimmed,
      'format': 'json',
      'limit': '1',
      'countrycodes': ?countryCode,
    });

    final response = await http.get(
      uri,
      // Required by Nominatim's usage policy — identify your app.
      headers: {'User-Agent': 'com.example.tuan5/1.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('Geocoding failed: HTTP ${response.statusCode}');
    }

    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat'] as String? ?? '');
    final lon = double.tryParse(first['lon'] as String? ?? '');

    if (lat == null || lon == null) return null;

    return GeocodeResult(
      latitude: lat,
      longitude: lon,
      displayName: first['display_name'] as String? ?? trimmed,
    );
  }
}