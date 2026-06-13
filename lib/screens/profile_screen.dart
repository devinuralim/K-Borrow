import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../main.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  final Color primaryNavy = const Color(0xFF1d3557);
  final Color secondaryBlue = const Color(0xFF457b9d);
  final Color darkBg = const Color(0xFF0F172A);
  final Color darkCard = const Color(0xFF1E293B);

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF1F5F9);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade700;
  Color get borderColor => isDarkMode ? Colors.white10 : Colors.grey.shade200;

  void initState() {
    super.initState();
    _fetchProfile();
    _updateTokenToDatabase();
  }

  Future<void> _updateTokenToDatabase() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        final authToken = await AuthService.getToken();

        await http.post(
          Uri.parse("${AppConfig.baseUrl}/v1/update-fcm-token"),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $authToken",
          },
          body: jsonEncode({
            "fcm_token": fcmToken,
          }),
        );
      }
    } catch (e) {
      debugPrint("ERROR NOTIFIKASI: $e");
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);

        setState(() {
          userData = data['user'];
          karyawanData = data['karyawan'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget build(BuildContext context) {
    final String nameToDisplay =
        (karyawanData?['nama_lengkap'] ?? userData?['name'] ?? "User K2NET")
            .toString();

    final String jabatanToDisplay =
        (karyawanData?['jabatan'] ?? "Pegawai K2NET").toString();

    final String emailToDisplay = (userData?['email'] ?? "-").toString();

    final String noWaToDisplay = (userData?['no_wa'] ??
            userData?['no_hp'] ??
            karyawanData?['no_wa'] ??
            karyawanData?['no_hp'] ??
            "-")
        .toString();

    final String alamatToDisplay =
        (userData?['alamat'] ?? karyawanData?['alamat'] ?? "-").toString();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text(
              "Profil Pegawai",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: isDarkMode ? darkCard : primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: primaryNavy,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchProfile();
                    await _updateTokenToDatabase();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            bottom: 35,
                            top: 14,
                            left: 20,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? darkCard : primaryNavy,
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
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundImage:
                                          userData?['foto_profile'] != null &&
                                                  userData!['foto_profile']
                                                      .toString()
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  userData!['foto_profile'],
                                                )
                                              : null,
                                      child: userData?['foto_profile'] == null
                                          ? const Icon(Icons.person, size: 60)
                                          : null,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(
                                            userData: userData,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        _fetchProfile();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: secondaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? darkCard
                                              : primaryNavy,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                nameToDisplay,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  jabatanToDisplay.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfo(
                                      "ID PEGAWAI",
                                      (karyawanData?['id_pegawai'] ?? "-")
                                          .toString(),
                                      Icons.badge_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildInfo(
                                      "STATUS",
                                      "Aktif",
                                      Icons.verified_user_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfo(
                                "EMAIL",
                                emailToDisplay,
                                Icons.email_rounded,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 20),
                              _buildInfo(
                                "NO WHATSAPP",
                                noWaToDisplay,
                                Icons.phone_rounded,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 20),
                              _buildInfo(
                                "ALAMAT",
                                alamatToDisplay,
                                Icons.location_on_rounded,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 20),
                              _buildInfo(
                                "TANGGAL BERGABUNG",
                                (karyawanData?['tanggal_bergabung'] ?? "-")
                                    .toString(),
                                Icons.calendar_month_rounded,
                                fullWidth: true,
                              ),
                              const SizedBox(height: 25),
                              _buildActionButton(
                                title: "Ganti Password",
                                subtitle: "Perbarui password akun kamu",
                                icon: Icons.lock_reset_rounded,
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                title: "Keluar dari Aplikasi",
                                subtitle: "Logout dari akun ini",
                                icon: Icons.logout_rounded,
                                color: Colors.red,
                                onTap: _logout,
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
      },
    );
  }

  Widget _buildInfo(
    String label,
    String value,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.blueGrey.shade200 : Colors.blueGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDarkMode ? Colors.white : primaryNavy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDarkMode
                    ? Colors.blueGrey.shade200
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
