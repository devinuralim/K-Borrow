import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  /// ==============================
  /// LOGIN
  /// ==============================
  static Future<UserModel?> login(String idPegawai, String password) async {
    final url = Uri.parse("${AppConfig.baseUrl}/v1/login");

    print("==== LOGIN START ====");
    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "id_pegawai": idPegawai,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      print("STATUS CODE : ${response.statusCode}");
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['user'] == null || data['token'] == null) {
          throw "Data user atau token kosong dari server";
        }

        Map<String, dynamic> userJson = data['user'];
        String token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("user", jsonEncode(userJson));

        print("SUCCESS: Token & User saved");
        return UserModel.fromJson(userJson);
      } else {
        // Ambil pesan error dari Laravel (misal: "Password salah")
        String msg = data['message'] ?? "Gagal Login (${response.statusCode})";
        throw msg;
      }
    } catch (e) {
      print("LOGIN EXCEPTION: $e");
      rethrow; // Lempar error ke UI Login
    } finally {
      print("==== LOGIN END ====");
    }
  }

  /// ==============================
  /// GET TOKEN
  /// ==============================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// ==============================
  /// GET USER DATA
  /// ==============================
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userString = prefs.getString("user");
    if (userString != null) {
      try {
        return UserModel.fromJson(jsonDecode(userString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// ==============================
  /// LOGOUT
  /// ==============================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("LOGOUT SUCCESS");
  }
}