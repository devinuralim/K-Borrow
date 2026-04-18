import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import '../models/barang_model.dart';

class FavoritService {
  // Ambil semua barang favorit
  static Future<List<BarangModel>> getFavorit() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/v1/favorit-barang");

    final response = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((e) => BarangModel.fromJson(e)).toList();
    } else {
      print("Gagal ambil favorit: ${response.body}");
      return [];
    }
  }

  // Toggle favorit
  // lib/services/favorit_service.dart
static Future<Map<String, dynamic>?> toggleFavorit(int barangId) async {
  final token = await AuthService.getToken();
  final url = Uri.parse("${AppConfig.baseUrl}/v1/favorit-barang/$barangId"); // pastikan ada /v1

  final response = await http.post(
    url,
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    print("Toggle favorit gagal: ${response.body}");
    return null;
  }
}
}