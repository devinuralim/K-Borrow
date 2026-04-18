import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'barang_screen.dart';
import 'peminjaman_screen.dart';
import 'favorit_screen.dart';
import 'riwayat_peminjaman_screen.dart';
import 'laporan_screen.dart';
import 'riwayat_laporan_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';

// --- KONSTANTA WARNA ---
const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color accentBlue = Color(0xFFa8dadc);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
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
  int currentActiveReports = 0;
  bool isLoading = true;

  List<dynamic> allNotifData = [];
  List<String> readIds = [];
  bool hasNewNotification = false;

  // ================= GLOBAL DARK MODE =================
  bool get isDarkMode =>
      MyApp.themeNotifier.value == ThemeMode.dark;

  // ================= WARNA =================
  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF8FAFC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryBlue;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupInteractedMessage();
    _updateTokenToDatabase();
  }

  // ================= LOAD =================
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      readIds = prefs.getStringList('read_notif_ids') ?? [];
    });

    await _fetchDashboardAndProfile();
  }

  // ================= TOGGLE =================
  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark =
        MyApp.themeNotifier.value == ThemeMode.dark;

    // ubah global
    MyApp.themeNotifier.value =
        isDark ? ThemeMode.light : ThemeMode.dark;

    // simpan
    prefs.setBool('isDarkMode', !isDark);
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['tab_index'] == '1' || message.data['screen'] == 'HOME_SCREEN') {
      setState(() => _selectedIndex = 1);
    }
  }

  Future<void> _updateTokenToDatabase() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final String? authToken = await AuthService.getToken();
        await http.post(
          Uri.parse("http://10.24.65.212:8000/api/v1/update-fcm-token"),
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
      final headers = {"Accept": "application/json", "Authorization": "Bearer $token"};

      final profileRes = await http.get(Uri.parse("http://10.24.65.212:8000/api/v1/profile"), headers: headers);
      final barangRes = await http.get(Uri.parse("http://10.24.65.212:8000/api/v1/barang"), headers: headers);
      final pinjamRes = await http.get(Uri.parse("http://10.24.65.212:8000/api/v1/peminjaman"), headers: headers);
      final laporanRes = await http.get(Uri.parse("http://10.24.65.212:8000/api/v1/laporan"), headers: headers);

      if (profileRes.statusCode == 200) {
        final profileBody = jsonDecode(profileRes.body);
        final barangData = jsonDecode(barangRes.body);
        final pinjamData = jsonDecode(pinjamRes.body);
        final laporanData = jsonDecode(laporanRes.body);

        setState(() {
          userData = profileBody['user'];
          karyawanData = profileBody['karyawan'];
          userName = karyawanData?['nama_lengkap'] ?? userData?['name'] ?? "User K2NET";

          totalBarang = (barangData['data'] ?? []).length;
          totalPeminjaman = (pinjamData['data'] ?? []).length;
          
          var listPinjam = pinjamData['data'] ?? [];
          currentActiveLoans = listPinjam.where((item) => 
              item['status'].toString().toLowerCase().trim() == 'dipinjam').length;

          var listLaporan = laporanData['data'] ?? [];
          currentActiveReports = listLaporan.where((item) => 
              item['status'].toString().toLowerCase().trim() != 'selesai').length;

          DateTime now = DateTime.now();
          allNotifData = listPinjam.where((item) {
            String status = item['status'].toString().toLowerCase().trim();
            if (status.contains('kembali')) return true;
            if (status.contains('pinjam') || status.contains('konfirmasi')) {
              if (item['created_at'] == null) return false;
              DateTime tglPinjam = DateTime.parse(item['created_at']);
              return now.difference(tglPinjam).inHours >= 12;
            }
            return false;
          }).toList();
          
          allNotifData.sort((a, b) => b['id'].compareTo(a['id']));
          hasNewNotification = allNotifData.any((item) => !readIds.contains(item['id'].toString()));
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

 @override
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
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildBerandaContent(),
                  _buildNotifikasiContent(),
                  _buildProfileContent()
                ],
              ),
        bottomNavigationBar: _buildBottomNav(),
      );
    },
  );
}

  // --- BERANDA SCREEN ---
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
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 45),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode ? [darkCard, darkBg] : [primaryBlue, Color(0xFF2b4a72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Halo,", style: TextStyle(color: accentBlue.withValues(alpha: 0.8), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    onPressed: _toggleDarkMode,
                    icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                  )
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
                        _buildStatCard("Total Barang", "$totalBarang", Icons.inventory_2_rounded, Colors.blue),
                        const SizedBox(width: 15),
                        _buildStatCard("Peminjaman", "$totalPeminjaman", Icons.swap_horiz_rounded, Colors.teal),
                      ],
                    ),
                  ),
                  _buildCategoryHeader("Menu Utama"),
                  _buildMenuContainer([
                    _menuItem("Daftar Barang", Icons.dashboard_customize_rounded, const BarangScreen()),
                    _menuItem("Barang Favorit", Icons.favorite_rounded, const FavoritScreen()),
                  ]),
                  _buildCategoryHeader("Aktivitas"),
                  _buildMenuContainer([
                    _menuItem("Form Peminjaman", Icons.add_box_rounded, const PeminjamanScreen()),
                    _menuItem("Riwayat Pinjam", Icons.history_rounded, const RiwayatPeminjamanScreen(), badgeCount: currentActiveLoans),
                  ]),
                  _buildCategoryHeader("Laporan"),
                  _buildMenuContainer([
                    _menuItem("Lapor Masalah", Icons.bug_report_rounded, const LaporanScreen()),
                    _menuItem("Status Laporan", Icons.assignment_turned_in_rounded, const RiwayatLaporanScreen(), badgeCount: currentActiveReports),
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

  // --- NOTIFIKASI SCREEN (NEW UI) ---
Widget _buildNotifikasiContent() {
  return Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
        decoration: BoxDecoration(
          color: isDarkMode ? darkCard : primaryBlue,
        ),
        child: const Text(
          "Notifikasi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardAndProfile,
          child: allNotifData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          size: 60, color: subTextColor),
                      const SizedBox(height: 10),
                      Text(
                        "Belum ada notifikasi",
                        style: TextStyle(color: subTextColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: allNotifData.length,
                  itemBuilder: (context, index) {
                    final item = allNotifData[index];
                    final isSelesai = item['status']
                        .toString()
                        .toLowerCase()
                        .contains('kembali');
                    final isRead =
                        readIds.contains(item['id'].toString());

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isRead
                            ? null
                            : Border.all(
                                color: Colors.blue.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:
                                isDarkMode ? 0.3 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelesai
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade700
                                    ]
                                  : [
                                      Colors.orange.shade400,
                                      Colors.orange.shade700
                                    ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelesai
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          isSelesai
                              ? "Pengembalian Selesai"
                              : "Peringatan Pinjaman",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          item['barang']['nama_barang'],
                          style: TextStyle(color: subTextColor),
                        ),
                        trailing: !isRead
                            ? const CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.blue,
                              )
                            : null,
                        onTap: () async {
                          if (!isRead) {
                            readIds.add(item['id'].toString());

                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setStringList(
                                'read_notif_ids', readIds);

                            setState(() {
                              hasNewNotification = allNotifData.any(
                                (n) => !readIds.contains(
                                    n['id'].toString()),
                              );
                            });
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RiwayatPeminjamanScreen(
                                highlightId:
                                    item['id'].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    ],
  );
}

  // --- PROFIL SCREEN ---
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue, secondaryBlue], begin: Alignment.topCenter, end: Alignment.bottomCenter), 
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))
            ),
            child: Column(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 60, color: primaryBlue)),
                const SizedBox(height: 15),
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text((karyawanData?['jabatan'] ?? "Pegawai").toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2))
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildProfileInfoCard("ID PEGAWAI", (karyawanData?['id_pegawai'] ?? "-").toString(), Icons.badge_outlined),
                _buildProfileInfoCard("TANGGAL GABUNG", (karyawanData?['tanggal_bergabung'] ?? "-").toString(), Icons.calendar_today_rounded),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, 
                  child: TextButton.icon(
                     style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15), 
                      backgroundColor: Colors.red.withValues(alpha: 0.05), // Ubah di sini
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                      foregroundColor: Colors.red
                    ),
                    onPressed: () async { 
                      await AuthService.logout(); 
                      if (!mounted) return;
Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                    }, 
                    icon: const Icon(Icons.logout_rounded, size: 20), 
                    label: const Text("Keluar dari Aplikasi", style: TextStyle(fontWeight: FontWeight.bold))
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REUSABLE HELPERS ---
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: cardColor, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -5))]),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: isDarkMode ? accentBlue : primaryBlue,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardColor,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Stack(children: [
              const Icon(Icons.notifications_none_rounded),
              if (hasNewNotification) Positioned(right: 0, top: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: cardColor, width: 1.5)))),
            ]),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(padding: const EdgeInsets.only(top: 25, bottom: 12, left: 4), child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)));
  }

  Widget _buildMenuContainer(List<Widget> items) {
    return Container(
  decoration: BoxDecoration(
    color: cardColor, 
    borderRadius: BorderRadius.circular(24), 
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02), // Ubah di sini
        blurRadius: 10, 
        offset: const Offset(0, 4)
      )
    ]
  ), 
  child: Column(children: items)
);
  }

  Widget _menuItem(String title, IconData icon, Widget destination, {int badgeCount = 0}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDarkMode ? darkBg : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isDarkMode ? accentBlue : primaryBlue, size: 18)),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange[800], borderRadius: BorderRadius.circular(10)), child: Text("$badgeCount Aktif", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
        ],
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
    );
  }

  Widget _buildProfileInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade100)),
      child: Row(children: [
        Icon(icon, color: secondaryBlue, size: 20),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: subTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        ]),
      ]),
    );
  }
}