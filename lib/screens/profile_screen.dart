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
  final Color accentBlue = const Color(0xFFa8dadc);
  final Color darkBg = const Color(0xFF0F172A);
  final Color darkCard = const Color(0xFF1E293B);

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF6F8FC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryNavy;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;
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
          body: jsonEncode({"fcm_token": fcmToken}),
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
      debugPrint("PROFILE ERROR: $e");

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget build(BuildContext context) {
    final String nameToDisplay =
        (karyawanData?['nama_lengkap'] ?? userData?['name'] ?? "User K2NET")
            .toString();

    final String jabatanToDisplay =
        (karyawanData?['jabatan'] ?? "Pegawai K2NET").toString();

    final String idPegawai =
        (karyawanData?['id_pegawai'] ?? userData?['id_pegawai'] ?? "-")
            .toString();

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
          body: SafeArea(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? accentBlue : primaryNavy,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchProfile();
                      await _updateTokenToDatabase();
                    },
                    color: primaryNavy,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      children: [
                        _buildTopHeader(
                          nameToDisplay,
                          jabatanToDisplay,
                        ),
                        const SizedBox(height: 18),
                        _buildIdentityStrip(idPegawai),
                        const SizedBox(height: 14),
                        _buildInfoPanel(
                          emailToDisplay,
                          noWaToDisplay,
                          alamatToDisplay,
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(String name, String jabatan) {
    final String? foto = userData?['foto_profile']?.toString();

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryNavy, secondaryBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryNavy.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundColor: cardColor,
                backgroundImage:
                    foto != null && foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto == null || foto.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkMode ? accentBlue : primaryNavy,
                      )
                    : null,
              ),
            ),
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userData: userData),
                  ),
                );

                if (result == true) {
                  _fetchProfile();
                }
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: secondaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: bgColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryNavy, secondaryBlue],
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            jabatan.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStrip(String idPegawai) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [darkCard, const Color(0xFF111827)]
              : [primaryNavy, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(isDarkMode ? 0.12 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _stripItem(
              "ID Pegawai",
              idPegawai,
              Icons.badge_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: Colors.white.withOpacity(0.20),
          ),
          Expanded(
            child: _stripItem(
              "Status",
              "Aktif",
              Icons.verified_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 21),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(String email, String noWa, String alamat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _infoTile(
            "Email",
            email,
            Icons.email_rounded,
            Colors.blue,
          ),
          _divider(),
          _infoTile(
            "No WhatsApp",
            noWa,
            Icons.phone_rounded,
            Colors.green,
          ),
          _divider(),
          _infoTile(
            "Alamat",
            alamat,
            Icons.location_on_rounded,
            Colors.orange,
            maxLines: 2,
          ),
          _divider(),
          _actionTile(
            title: "Ubah Password",
            subtitle: "Ganti kata sandi akun",
            icon: Icons.lock_reset_rounded,
            color: Colors.deepOrange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _divider(),
          _actionTile(
            title: "Logout",
            subtitle: "Keluar dari akun ini",
            icon: Icons.logout_rounded,
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    String label,
    String value,
    IconData icon,
    Color color, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: subTextColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      ),
    );
  }
}
