import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'barang_screen.dart';
import 'favorit_screen.dart';
import 'riwayat_peminjaman_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../config/app_config.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import '../models/barang_model.dart';
import '../services/cart_service.dart';
import 'keranjang_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color accentBlue = Color(0xFFa8dadc);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String userName = "Memuat...";
  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  int totalBarang = 0;
  int totalPeminjaman = 0;
  int currentActiveLoans = 0;
  bool isLoading = true;

  List<dynamic> allNotifData = [];
  List<dynamic> rekomendasiBarang = [];
  List<String> readIds = [];
  bool hasNewNotification = false;

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF8FAFC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryBlue;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;
  Color get borderColor => isDarkMode ? Colors.white10 : Colors.grey.shade200;

  void initState() {
    super.initState();
    _loadInitialData();
    _setupInteractedMessage();
    _updateTokenToDatabase();
  }

  bool _isActivePeminjaman(dynamic item) {
    final status = item['status'].toString().toLowerCase().trim();

    if (status == 'selesai') return false;
    if (status == 'ditolak') return false;

    if (status == 'digunakan') {
      final tanggal = item['tanggal_pinjam'] ?? item['created_at'];
      if (tanggal == null) return true;

      try {
        final tgl = DateTime.parse(tanggal.toString()).toLocal();
        return DateTime.now().difference(tgl).inHours < 8;
      } catch (_) {
        return true;
      }
    }

    return true;
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      readIds = prefs.getStringList('read_notif_ids') ?? [];
    });

    await _fetchDashboardAndProfile();
  }

  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;

    MyApp.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    prefs.setBool('isDarkMode', !isDark);
  }

  Future<void> _setupInteractedMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['tab_index'] == '1' ||
        message.data['screen'] == 'HOME_SCREEN') {
      setState(() => _selectedIndex = 1);
    }
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
      debugPrint("Error FCM: $e");
    }
  }

  Future<void> _fetchDashboardAndProfile() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final profileRes = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/profile"),
        headers: headers,
      );

      final barangRes = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/barang"),
        headers: headers,
      );

      final rekomRes = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/barang-rekomendasi"),
        headers: headers,
      );

      final pinjamRes = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/peminjaman/riwayat"),
        headers: headers,
      );

      if (profileRes.statusCode == 200 &&
          barangRes.statusCode == 200 &&
          pinjamRes.statusCode == 200) {
        final profileBody = jsonDecode(profileRes.body);
        final barangData = jsonDecode(barangRes.body);
        final pinjamData = jsonDecode(pinjamRes.body);

        List rekomDataList = [];
        if (rekomRes.statusCode == 200) {
          final rekomData = jsonDecode(rekomRes.body);
          rekomDataList = rekomData['data'] ?? [];
        }

        final List listBarang = barangData['data'] ?? [];
        final List listPinjam = pinjamData['data'] ?? [];

        final activePinjam = listPinjam.where(_isActivePeminjaman).toList();

        activePinjam.sort((a, b) {
          final idA = int.tryParse(a['id'].toString()) ?? 0;
          final idB = int.tryParse(b['id'].toString()) ?? 0;
          return idB.compareTo(idA);
        });

        final notifData = activePinjam.where((item) {
          final status = item['status'].toString().toLowerCase().trim();

          return status == 'menunggu_konfirmasi_pengembalian' ||
              status == 'menunggu_perbaikan' ||
              status == 'menunggu_verifikasi_perbaikan' ||
              status == 'menunggu_ganti_rugi' ||
              status == 'menunggu_verifikasi_ganti_rugi' ||
              status == 'menunggu_ganti_barang' ||
              status == 'menunggu_verifikasi_ganti_barang' ||
              status == 'menunggu_perpanjangan';
        }).toList();

        if (!mounted) return;

        setState(() {
          userData = profileBody['user'];
          karyawanData = profileBody['karyawan'];

          userName = karyawanData?['nama_lengkap'] ??
              userData?['name'] ??
              "User K2NET";

          totalBarang = listBarang.length;
          totalPeminjaman = activePinjam.length;
          currentActiveLoans = activePinjam.length;

          rekomendasiBarang = rekomDataList;
          allNotifData = notifData;

          hasNewNotification = allNotifData.any(
            (item) => !readIds.contains(item['id'].toString()),
          );

          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            toolbarHeight: 0,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildBerandaContent(),
                    const NotificationScreen(),
                    const ProfileScreen(),
                  ],
                ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBerandaContent() {
    return RefreshIndicator(
      onRefresh: _fetchDashboardAndProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 34, 25, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [darkCard, darkBg]
                      : [primaryBlue, const Color(0xFF2b4a72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Halo,",
                          style: TextStyle(
                            color: accentBlue.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Kelola peminjaman barang inventaris dengan mudah.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleDarkMode,
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -25),
                    child: Row(
                      children: [
                        _buildStatCard(
                          "Total Barang",
                          "$totalBarang",
                          Icons.inventory_2_rounded,
                          Colors.blue,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          "Peminjaman Aktif",
                          "$totalPeminjaman",
                          Icons.swap_horiz_rounded,
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  if (rekomendasiBarang.isNotEmpty) ...[
                    _buildCategoryHeader("Rekomendasi Untuk Anda"),
                    _buildRekomendasiList(),
                    const SizedBox(height: 8),
                  ],
                  _buildCategoryHeader("Menu Utama"),
                  _buildMenuContainer([
                    _menuItem(
                      "Tambah Peminjaman",
                      Icons.dashboard_customize_rounded,
                      const BarangScreen(),
                    ),
                    _menuItem(
                      "Barang Favorit",
                      Icons.favorite_rounded,
                      const FavoritScreen(),
                    ),
                    _menuItem(
                      "Riwayat Pinjam",
                      Icons.history_rounded,
                      const RiwayatPeminjamanScreen(),
                      badgeCount: currentActiveLoans,
                    ),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekomendasiList() {
    return SizedBox(
      height: 132,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rekomendasiBarang.length,
        itemBuilder: (context, index) {
          final item = rekomendasiBarang[index];

          final namaBarang = item['nama_barang']?.toString() ?? '-';
          final jenisBarang = item['jenis_barang']?.toString() ?? 'Barang';
          final stok = item['stok']?.toString() ?? '0';
          final foto = item['foto_barang']?.toString() ??
              item['gambar']?.toString() ??
              item['image']?.toString() ??
              '';

          return InkWell(
            onTap: () {
              final barang = BarangModel.fromJson(item);

              CartService.tambahBarang(barang);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${barang.namaBarang} masuk ke keranjang"),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KeranjangScreen(
                    keranjang: CartService.keranjang,
                    semuaBarang: CartService.semuaBarang,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 185,
              margin: EdgeInsets.only(
                right: index == rekomendasiBarang.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDarkMode ? darkBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: foto.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              foto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Icon(
                                  Icons.inventory_2_rounded,
                                  color: isDarkMode ? accentBlue : primaryBlue,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.recommend_rounded,
                            color: Colors.orange.shade700,
                          ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Rekomendasi",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          namaBarang,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          jenisBarang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Stok: $stok",
                          style: TextStyle(
                            color: stok == '0'
                                ? Colors.red
                                : isDarkMode
                                    ? accentBlue
                                    : Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: isDarkMode ? accentBlue : primaryBlue,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardColor,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (hasNewNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 12, left: 4),
      child: Row(
        children: [
          if (title.toLowerCase().contains('rekomendasi')) ...[
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(
    String title,
    IconData icon,
    Widget destination, {
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? darkBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? accentBlue : primaryBlue,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$badgeCount",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey[400],
            ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => destination,
          ),
        );
      },
    );
  }
}
