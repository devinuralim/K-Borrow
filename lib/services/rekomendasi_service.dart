import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class RekomendasiService {
  static Future<List<dynamic>> getRekomendasi() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/barang-rekomendasi"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['data'] ?? [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}