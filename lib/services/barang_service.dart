import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/barang_model.dart';

class BarangService {
  // Masukkan langsung di sini agar tidak perlu import file lain
  static const String baseUrl = "http://10.24.65.212:8000/api";

  static Future<List<BarangModel>> getBarang() async {
    try {
      final token = await AuthService.getToken();
      // Gunakan variabel baseUrl di atas
      final url = Uri.parse("$baseUrl/v1/barang");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        return list.map((json) => BarangModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("ERROR GET BARANG: $e");
      return [];
    }
  }
}