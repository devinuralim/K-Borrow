import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import '../models/peminjaman_model.dart';

class PeminjamanService {
  static Future<List<PeminjamanModel>> getPeminjaman() async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse("${AppConfig.baseUrl}/v1/peminjaman/riwayat");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("STATUS RIWAYAT: ${response.statusCode}");
      print("BODY RIWAYAT: ${response.body}");

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

  static Future<bool> pinjamBanyakBarang({
    required List<Map<String, dynamic>> items,
    required File image,
    String? keterangan,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse("${AppConfig.baseUrl}/v1/peminjaman");

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['items'] = jsonEncode(
        items.map((e) {
          return {"barang_id": e["barang_id"], "jumlah": e["jumlah"]};
        }).toList(),
      );

      request.fields['keterangan_pinjam'] = keterangan ?? "";

      request.files.add(
        await http.MultipartFile.fromPath('foto_pinjam', image.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS PINJAM: ${response.statusCode}");
      print("BODY PINJAM: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("PINJAM ERROR: $e");
      return false;
    }
  }

  static Future<bool> kembalikanBarang({
    required int id,
    required String kondisiPengembalian,
    required String keterangan,
    File? image,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse(
        "${AppConfig.baseUrl}/v1/peminjaman/$id/upload-bukti",
      );

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['kondisi_pengembalian'] = kondisiPengembalian;
      request.fields['keterangan'] = keterangan;

      if (image != null && image.path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('bukti_pengembalian', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS PENGEMBALIAN: ${response.statusCode}");
      print("BODY PENGEMBALIAN: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("Exception saat kirim pengembalian: $e");
      return false;
    }
  }

  static Future<bool> kembalikanBarangMassal({
    required List<int> ids,
    required String kondisiPengembalian,
    required String keterangan,
    File? image,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse(
        "${AppConfig.baseUrl}/v1/peminjaman/kembali-massal",
      );

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      for (int i = 0; i < ids.length; i++) {
        request.fields['peminjaman_ids[$i]'] = ids[i].toString();
      }

      request.fields['kondisi_pengembalian'] = kondisiPengembalian;
      request.fields['keterangan'] = keterangan;

      if (image != null && image.path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'bukti_pengembalian',
            image.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS PENGEMBALIAN MASSAL: ${response.statusCode}");
      print("BODY PENGEMBALIAN MASSAL: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("Exception pengembalian massal: $e");
      return false;
    }
  }

  static Future<bool> uploadPerbaikan({
    required int id,
    required File buktiPerbaikan,
    required String keterangan,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse(
        "${AppConfig.baseUrl}/v1/peminjaman/$id/upload-perbaikan",
      );

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['keterangan_tindak_lanjut'] = keterangan;

      request.files.add(
        await http.MultipartFile.fromPath(
          'bukti_perbaikan',
          buktiPerbaikan.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS UPLOAD PERBAIKAN: ${response.statusCode}");
      print("BODY UPLOAD PERBAIKAN: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("UPLOAD PERBAIKAN ERROR: $e");
      return false;
    }
  }

  static Future<bool> uploadGantiRugi({
    required int id,
    required File buktiTransfer,
    String? keterangan,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse(
        "${AppConfig.baseUrl}/v1/peminjaman/$id/upload-ganti-rugi",
      );

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['keterangan_tindak_lanjut'] = keterangan ?? "";

      request.files.add(
        await http.MultipartFile.fromPath(
          'bukti_ganti_rugi',
          buktiTransfer.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS UPLOAD GANTI RUGI: ${response.statusCode}");
      print("BODY UPLOAD GANTI RUGI: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("UPLOAD GANTI RUGI ERROR: $e");
      return false;
    }
  }

  static Future<bool> uploadGantiBarang({
    required int id,
    required File buktiBarang,
    required String keterangan,
  }) async {
    try {
      final token = await AuthService.getToken();

      final url = Uri.parse(
        "${AppConfig.baseUrl}/v1/peminjaman/$id/upload-ganti-barang",
      );

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['keterangan_tindak_lanjut'] = keterangan;

      request.files.add(
        await http.MultipartFile.fromPath(
          'bukti_ganti_barang',
          buktiBarang.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS UPLOAD GANTI BARANG: ${response.statusCode}");
      print("BODY UPLOAD GANTI BARANG: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("UPLOAD GANTI BARANG ERROR: $e");
      return false;
    }
  }
}
