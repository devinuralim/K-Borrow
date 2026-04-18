import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import '../models/peminjaman_model.dart';

class PeminjamanService {

  // --- Ambil Riwayat Peminjaman ---
  static Future<List<PeminjamanModel>> getPeminjaman() async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("${AppConfig.baseUrl}/v1/peminjaman");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        return data.map((json) => PeminjamanModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error getPeminjaman: $e");
      return [];
    }
  }

  // --- Kirim Banyak Barang Sekaligus (MULTI ITEM - FIXED) ---
  static Future<bool> pinjamBanyakBarang({
    required List<Map<String, dynamic>> items,
    String? keterangan,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("${AppConfig.baseUrl}/v1/peminjaman");

      // CLEANING DATA: Laravel hanya butuh barang_id dan jumlah.
      // Kita hapus key "nama" supaya tidak mengganggu validator Laravel.
      List<Map<String, dynamic>> cleanedItems = items.map((e) {
        return {
          "barang_id": e["barang_id"],
          "jumlah": e["jumlah"],
        };
      }).toList();

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "items": cleanedItems,
          "keterangan": keterangan ?? "",
          "tanggal_pinjam": DateTime.now().toIso8601String(),
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true; 
      }

      return false;
    } catch (e) {
      print("Exception multi pinjam: $e");
      return false;
    }
  }

  // --- Kirim Bukti Pengembalian (Multipart) ---
  static Future<bool> kembalikanBarang({
    required int id,
    required String keterangan,
    required File image,
  }) async {
    try {
      final token = await AuthService.getToken();
      // SESUAIKAN URL: Pastikan route di Laravel adalah /peminjaman/{id}/upload-bukti
      final url = Uri.parse("${AppConfig.baseUrl}/v1/peminjaman/$id/upload-bukti");

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['keterangan'] = keterangan;

      // Ambil file gambar
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_pengembalian',
        image.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("Pengembalian Berhasil");
        return true;
      } else {
        print("Gagal Kirim. Status: ${response.statusCode}");
        print("Respon Server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception saat kirim bukti: $e");
      return false;
    }
  }
}