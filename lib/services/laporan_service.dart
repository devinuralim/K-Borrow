import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/laporan_model.dart'; // Pastikan import modelnya benar

class LaporanService {
  static const String baseUrl = "http://10.24.65.212:8000/api";

  // --- FUNGSI KIRIM (YANG SUDAH ADA) ---
  static Future<bool> kirimLaporan({
    required int barangId,
    required String jenis,
    required int jumlah,
    required String deskripsi,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/v1/laporan");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "barang_id": barangId,
          "jenis_laporan": jenis,
          "jumlah": jumlah,
          "keterangan": deskripsi,
          "deskripsi": deskripsi,
        }),
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  // --- TAMBAHKAN FUNGSI INI (UNTUK RIWAYAT) ---
  static Future<List<LaporanModel>> getLaporan() async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/v1/laporan");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];
        return data.map((item) => LaporanModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error Get Laporan: $e");
      return [];
    }
  }
}