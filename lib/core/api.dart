import 'package:http/http.dart' as http;

class Api {
  static const String baseUrl = 'https://api.example.com';

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, body: data);
  }
}