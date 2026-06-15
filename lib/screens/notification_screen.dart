import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  State<NotificationScreen> createState() {
    return _NotificationScreenState();
  }
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : const Color(0xFFF6F8FC);
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryBlue;
  Color get subTextColor =>
      isDarkMode ? Colors.blueGrey.shade200 : Colors.grey.shade600;
  Color get borderColor =>
      isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

  void initState() {
    super.initState();
    _loadAllNotifications();
  }

  Future<void> _loadAllNotifications() async {
    setState(() => isLoading = true);

    final List<Map<String, dynamic>> data = [];

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedData = prefs.getStringList('fcm_notifications') ?? [];

      for (final item in savedData) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            data.add(Map<String, dynamic>.from(decoded));
          }
        } catch (e) {
          debugPrint("Notif decode error: $e");
        }
      }

      final lateNotifications = await _getLatePeminjamanNotifications();

      for (final notif in lateNotifications) {
        final exists = data.any((item) {
          return item['type'] == 'late_peminjaman' &&
              item['peminjaman_id'].toString() ==
                  notif['peminjaman_id'].toString();
        });

        if (!exists) {
          data.add(notif);
        }
      }

      data.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Load notification error: $e");

      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getLatePeminjamanNotifications() async {
    final List<Map<String, dynamic>> lateData = [];

    try {
      final token = await AuthService.getToken();

      final res = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/peminjaman/riwayat"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("CEK TELAT STATUS: ${res.statusCode}");
      debugPrint("CEK TELAT BODY: ${res.body}");

      if (res.statusCode != 200) return lateData;

      final body = jsonDecode(res.body);
      final List listPinjam = body['data'] ?? [];

      for (final item in listPinjam) {
        final status = item['status']?.toString().toLowerCase().trim() ?? '';

        if (status != 'digunakan' && status != 'dipinjam') continue;

        final tanggalRaw = item['tanggal_pinjam'] ?? item['created_at'];
        if (tanggalRaw == null) continue;

        DateTime? tanggalPinjam;

        try {
          tanggalPinjam = DateTime.parse(tanggalRaw.toString()).toLocal();
        } catch (_) {
          tanggalPinjam = null;
        }

        if (tanggalPinjam == null) continue;

        final sudahBerapaJam = DateTime.now().difference(tanggalPinjam).inHours;

        if (sudahBerapaJam >= 8) {
          final namaBarang = _getNamaBarang(item);

          lateData.add({
            "type": "late_peminjaman",
            "peminjaman_id": item['id']?.toString() ?? '',
            "title": "Barang segera dikembalikan",
            "body":
                "$namaBarang sudah dipinjam lebih dari 8 jam. Segera kembalikan barang ke admin.",
            "created_at": DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint("Late peminjaman error: $e");
    }

    return lateData;
  }

  String _getNamaBarang(dynamic item) {
    try {
      if (item['barang'] != null) {
        final barang = item['barang'];
        return barang['nama_barang']?.toString() ??
            barang['nama']?.toString() ??
            "Barang";
      }

      return item['nama_barang']?.toString() ??
          item['barang_nama']?.toString() ??
          item['nama']?.toString() ??
          "Barang";
    } catch (_) {
      return "Barang";
    }
  }

  Future<void> _clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_notifications');

      if (!mounted) return;

      setState(() {
        notifications.clear();
      });
    } catch (e) {
      debugPrint("Clear notification error: $e");
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    } catch (e) {
      return '';
    }
  }

  String _safeText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: isLoading
                          ? _buildLoading()
                          : notifications.isEmpty
                              ? _buildEmptyState()
                              : _buildNotificationList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifikasi",
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                notifications.isEmpty
                    ? "Belum ada update terbaru"
                    : "${notifications.length} notifikasi tersimpan",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _headerButton(
          icon: Icons.refresh_rounded,
          onTap: _loadAllNotifications,
        ),
        const SizedBox(width: 8),
        _headerButton(
          icon: Icons.delete_outline_rounded,
          onTap: _clearNotifications,
          danger: true,
        ),
      ],
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: danger
              ? Colors.red.withOpacity(0.10)
              : isDarkMode
                  ? darkCard
                  : Colors.white,
          border: Border.all(
            color: danger ? Colors.red.withOpacity(0.20) : borderColor,
          ),
        ),
        child: Icon(
          icon,
          color: danger
              ? Colors.red
              : isDarkMode
                  ? accentBlue
                  : primaryBlue,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: isDarkMode ? accentBlue : primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadAllNotifications,
      color: primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(
            Icons.notifications_none_rounded,
            size: 78,
            color: isDarkMode
                ? accentBlue.withOpacity(0.55)
                : primaryBlue.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada notifikasi",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            "Update peminjaman barang akan muncul di sini.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadAllNotifications,
      color: primaryBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          final title = _safeText(item['title'], 'Notifikasi');
          final body = _safeText(item['body'], 'Tidak ada isi notifikasi.');
          final createdAt = _formatDate(item['created_at']?.toString());
          final isLate = item['type'] == 'late_peminjaman';

          return _notificationItem(
            title: title,
            body: body,
            createdAt: createdAt,
            index: index,
            isLate: isLate,
          );
        },
      ),
    );
  }

  Widget _notificationItem({
    required String title,
    required String body,
    required String createdAt,
    required int index,
    required bool isLate,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          _showDetailDialog(title, body, createdAt);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isLate ? Colors.red.withOpacity(0.45) : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.035),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLate
                        ? [Colors.red, Colors.red.shade700]
                        : [primaryBlue, secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLate
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLate ? Colors.red : textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            createdAt,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: subTextColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(String title, String body, String createdAt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: title.toLowerCase().contains('dikembalikan')
                  ? Colors.red
                  : textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            createdAt.isEmpty ? body : "$body\n\n$createdAt",
            style: TextStyle(
              color: subTextColor,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}