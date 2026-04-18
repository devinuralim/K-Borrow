import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart'; // Tambah ini
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  final Color primaryNavy = const Color(0xFF1d3557);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _updateTokenToDatabase(); // Tambahkan ini agar saat buka profil, token HP dikirim ke Laravel
  }

  // --- FUNGSI BARU: KIRIM ALAMAT HP KE LARAVEL ---
  Future<void> _updateTokenToDatabase() async {
    try {
      // 1. Ambil Token dari Firebase
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null) {
        debugPrint("FCM TOKEN HP: $fcmToken");

        // 2. Ambil Bearer Token untuk keamanan
        final String? authToken = await AuthService.getToken();
        
        // 3. Kirim ke API Laravel yang baru kita buat tadi
        final response = await http.post(
          Uri.parse("http://10.24.65.212:8000/api/v1/update-fcm-token"),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $authToken",
          },
          body: jsonEncode({"fcm_token": fcmToken}),
        );

        if (response.statusCode == 200) {
          debugPrint("NOTIFIKASI: Berhasil mendaftarkan HP ke server.");
        } else {
          debugPrint("NOTIFIKASI GAGAL: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("ERROR NOTIFIKASI: $e");
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("http://10.24.65.212:8000/api/v1/profile");
      
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data['user'];
          karyawanData = data['karyawan'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("EXCEPTION: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String nameToDisplay = (karyawanData?['nama_lengkap'] ?? userData?['name'] ?? "Memuat...").toString();
    String jabatanToDisplay = (karyawanData?['jabatan'] ?? "Pegawai K2NET").toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Profil Pegawai", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryNavy))
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchProfile();
                await _updateTokenToDatabase();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // --- HEADER MELENGKUNG ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 35, top: 10),
                      decoration: BoxDecoration(
                        color: primaryNavy,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, size: 60, color: Color(0xFF1d3557)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.white, size: 15),
                              )
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            nameToDisplay,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              jabatanToDisplay.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- CONTENT ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildInfo("ID PEGAWAI", (karyawanData?['id_pegawai'] ?? "-").toString(), Icons.badge)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildInfo("STATUS", "Aktif", Icons.verified_user)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfo("TANGGAL BERGABUNG", (karyawanData?['tanggal_bergabung'] ?? "-").toString(), Icons.calendar_month, fullWidth: true),
                          
                          const SizedBox(height: 30),

                          // --- NOTIFIKASI AKSES ---
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_person_outlined, color: Colors.orange, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Informasi Akun",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Data profil ini dikelola oleh sistem K2NET. Hubungi Admin jika ada kesalahan data.",
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfo(String label, String value, IconData icon, {bool fullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: primaryNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}