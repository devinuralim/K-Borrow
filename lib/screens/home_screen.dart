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
import 'history_peminjaman_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color accentBlue = Color(0xFFa8dadc);
const Color lightBg = Color(0xFFF6F8FC);
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
  List<dynamic> leaderboardData = [];
  bool hasNewNotification = false;

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : lightBg;
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

      final leaderboardRes = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/leaderboard-peminjaman"),
        headers: headers,
      );

      debugPrint("PEMINJAMAN STATUS: ${pinjamRes.statusCode}");
      debugPrint("PEMINJAMAN BODY: ${pinjamRes.body}");
      debugPrint("LEADERBOARD STATUS: ${leaderboardRes.statusCode}");
      debugPrint("LEADERBOARD BODY: ${leaderboardRes.body}");

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

        List leaderboardList = [];
        if (leaderboardRes.statusCode == 200) {
          final leaderboardBody = jsonDecode(leaderboardRes.body);
          leaderboardList = leaderboardBody['data'] ?? [];
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
          leaderboardData = leaderboardList;
          allNotifData = notifData;

          hasNewNotification = allNotifData.any(
            (item) => !readIds.contains(item['id'].toString()),
          );

          debugPrint("ACTIVE LOANS = $currentActiveLoans");

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
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode ? accentBlue : primaryBlue,
                  ),
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
    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          );
        },
        child: RefreshIndicator(
          onRefresh: _fetchDashboardAndProfile,
          color: primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                children: [
                  _buildHeaderNatural(),
                  const SizedBox(height: 18),
                  _buildMiniStats(),
                  const SizedBox(height: 15),
                  _sectionTitle(
                    "Barang yang Sering Dipinjam",
                    Icons.trending_up_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(height: 9),
                  _buildSeringDipinjamMini(),
                  const SizedBox(height: 15),
                  _sectionTitle(
                    "Menu Utama",
                    Icons.dashboard_customize_rounded,
                    primaryBlue,
                  ),
                  const SizedBox(height: 9),
                  _buildMenuUtama(),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    "Top Peminjam Bulan Ini",
                    Icons.emoji_events_rounded,
                    Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  _buildLeaderboard(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (leaderboardData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          "Belum ada data leaderboard",
          style: TextStyle(
            color: subTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: List.generate(leaderboardData.length, (index) {
          final item = leaderboardData[index];

          String medal = "🏅";
          if (index == 0) medal = "🥇";
          if (index == 1) medal = "🥈";
          if (index == 2) medal = "🥉";

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              border: index != leaderboardData.length - 1
                  ? Border(bottom: BorderSide(color: borderColor))
                  : null,
            ),
            child: Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['nama'] ?? '-',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "${item['total_barang']} Barang",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeaderNatural() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo,",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: _toggleDarkMode,
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [accentBlue.withOpacity(0.75), secondaryBlue]
                    : [primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStats() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [darkCard, const Color(0xFF111827)]
              : [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(isDarkMode ? 0.12 : 0.20),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statInside(
              "Total Barang",
              "$totalBarang",
              Icons.category_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.18),
          ),
          Expanded(
            child: _statInside(
              "Sedang Dipinjam",
              "$totalPeminjaman",
              Icons.sync_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statInside(String title, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDarkMode && color == primaryBlue ? accentBlue : color,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeringDipinjamMini() {
    if (rekomendasiBarang.isEmpty) {
      return SizedBox(
        height: 82,
        child: Center(
          child: Text(
            "Belum ada data barang populer",
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: rekomendasiBarang.length > 5 ? 5 : rekomendasiBarang.length,
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
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final barang = BarangModel.fromJson(item);
              CartService.tambahBarang(barang);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${barang.namaBarang} masuk ke keranjang"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
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
            child: Container(
              width: 190,
              margin: EdgeInsets.only(
                right: index == rekomendasiBarang.length - 1 ? 0 : 11,
              ),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDarkMode ? darkBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: foto.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              foto,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return Icon(
                                  Icons.inventory_2_rounded,
                                  color: isDarkMode ? accentBlue : primaryBlue,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_rounded,
                            color: isDarkMode ? accentBlue : primaryBlue,
                          ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaBarang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          jenisBarang,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Stok $stok",
                          style: TextStyle(
                            color: stok == '0' ? Colors.red : Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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

  Widget _buildMenuUtama() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 135,
          child: Row(
            children: [
              Expanded(
                child: _menuPrimary(
                  title: "Buat Peminjaman",
                  subtitle: "Pilih barang",
                  icon: Icons.add_circle_rounded,
                  destination: const BarangScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _menuSimple(
                  title: "Favorit",
                  subtitle: "Barang pilihan",
                  icon: Icons.favorite_rounded,
                  color: Colors.pink,
                  destination: const FavoritScreen(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 135,
          child: Row(
            children: [
              Expanded(
                child: _menuSimple(
                  title: "Peminjaman Aktif",
                  subtitle: "Barang Yang dipinjam",
                  icon: Icons.assignment_rounded,
                  color: Colors.teal,
                  destination: const RiwayatPeminjamanScreen(),
                  badgeCount: currentActiveLoans,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _menuSimple(
                  title: "History",
                  subtitle: "Sudah selesai",
                  icon: Icons.history_rounded,
                  color: Colors.orange,
                  destination: const HistoryPeminjamanScreen(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuPrimary({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.22),
              blurRadius: 17,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -24,
              child: Icon(
                icon,
                size: 92,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 42),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSimple({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    int badgeCount = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 39),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
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
            if (badgeCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 25,
                    minHeight: 25,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: cardColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? "99+" : "$badgeCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.20 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          _bottomItem(index: 0, label: "Beranda", icon: Icons.home_rounded),
          _bottomItem(
            index: 1,
            label: "Notifikasi",
            icon: Icons.notifications_rounded,
            showDot: hasNewNotification,
          ),
          _bottomItem(index: 2, label: "Profil", icon: Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _bottomItem({
    required int index,
    required String label,
    required IconData icon,
    bool showDot = false,
  }) {
    final bool active = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          height: 50,
          decoration: BoxDecoration(
            color: active
                ? (isDarkMode
                    ? accentBlue.withOpacity(0.13)
                    : primaryBlue.withOpacity(0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: active
                        ? (isDarkMode ? accentBlue : primaryBlue)
                        : Colors.grey,
                    size: 22,
                  ),
                  if (showDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: active
                    ? Row(
                        children: [
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              color: isDarkMode ? accentBlue : primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
