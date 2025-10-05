import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String? sessionToken;

  ApiClient({
    required this.baseUrl,
    this.sessionToken,
  });

  String get normalizedBaseUrl => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (sessionToken != null) 'Session-Token': sessionToken!,
  };

  Future<http.Response> get(String endpoint, {Map<String, String>? additionalHeaders}) async {
    final url = Uri.parse('$normalizedBaseUrl$endpoint');
    return await http.get(
      url,
      headers: {...headers, if (additionalHeaders != null) ...additionalHeaders},
    );
  }

  Future<http.Response> post(
      String endpoint,
      Map<String, dynamic> body, {
        Map<String, String>? additionalHeaders,
      }) async {
    final url = Uri.parse('$normalizedBaseUrl$endpoint');
    return await http.post(
      url,
      headers: {...headers, if (additionalHeaders != null) ...additionalHeaders},
      body: jsonEncode(body),
    );
  }


  // ✅ Thêm PUT method
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$base$endpoint');

    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (sessionToken != null) 'Session-Token': sessionToken!,
      },
      body: jsonEncode(body),
    );
  }

}
