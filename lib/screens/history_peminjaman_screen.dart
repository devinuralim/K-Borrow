import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../main.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color accentBlue = Color(0xFFa8dadc);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);

class HistoryPeminjamanScreen extends StatefulWidget {
  const HistoryPeminjamanScreen({super.key});

  State<HistoryPeminjamanScreen> createState() =>
      _HistoryPeminjamanScreenState();
}

class _HistoryPeminjamanScreenState extends State<HistoryPeminjamanScreen> {
  bool isLoading = true;
  String selectedFilter = 'semua';

  List<dynamic> semuaHistory = [];
  List<dynamic> filteredHistory = [];

  bool get isDarkMode => MyApp.themeNotifier.value == ThemeMode.dark;

  Color get bgColor => isDarkMode ? darkBg : backgroundGray;
  Color get cardColor => isDarkMode ? darkCard : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : primaryBlue;
  Color get subTextColor => isDarkMode ? Colors.white60 : Colors.grey.shade600;
  Color get borderColor => isDarkMode ? Colors.white10 : Colors.grey.shade200;

  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/v1/peminjaman/history"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("HISTORY STATUS: ${response.statusCode}");
      debugPrint("HISTORY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? [];

        final selesaiOnly = data.where((item) {
          final status = item['status']?.toString().toLowerCase().trim() ?? '';
          return status == 'selesai';
        }).toList();

        selesaiOnly.sort((a, b) {
          final dateA = _getTanggalHistory(a);
          final dateB = _getTanggalHistory(b);
          return dateB.compareTo(dateA);
        });

        if (!mounted) return;

        setState(() {
          semuaHistory = selesaiOnly;
          isLoading = false;
        });

        applyFilter(selectedFilter);
      } else {
        if (!mounted) return;
        setState(() {
          semuaHistory = [];
          filteredHistory = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error history: $e");
      if (!mounted) return;
      setState(() {
        semuaHistory = [];
        filteredHistory = [];
        isLoading = false;
      });
    }
  }

  DateTime _getTanggalHistory(dynamic item) {
    final rawDate = item['updated_at'] ??
        item['tanggal_kembali'] ??
        item['tanggal_pinjam'] ??
        item['created_at'];

    if (rawDate == null) return DateTime(2000);

    try {
      return DateTime.parse(rawDate.toString()).toLocal();
    } catch (_) {
      return DateTime(2000);
    }
  }

  void applyFilter(String filter) {
    final now = DateTime.now();
    List<dynamic> result = [];

    if (filter == 'semua') {
      result = List.from(semuaHistory);
    } else if (filter == 'minggu') {
      final startWeekRaw = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startWeekRaw.year,
        startWeekRaw.month,
        startWeekRaw.day,
      );
      final end = start.add(const Duration(days: 7));

      result = semuaHistory.where((item) {
        final tanggal = _getTanggalHistory(item);
        return !tanggal.isBefore(start) && tanggal.isBefore(end);
      }).toList();
    } else if (filter == 'bulan') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      result = semuaHistory.where((item) {
        final tanggal = _getTanggalHistory(item);
        return !tanggal.isBefore(start) && tanggal.isBefore(end);
      }).toList();
    } else if (filter == 'tahun') {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year + 1, 1, 1);

      result = semuaHistory.where((item) {
        final tanggal = _getTanggalHistory(item);
        return !tanggal.isBefore(start) && tanggal.isBefore(end);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      selectedFilter = filter;
      filteredHistory = result;
    });
  }

  String _formatTanggal(dynamic item) {
    final tanggal = _getTanggalHistory(item);

    if (tanggal.year == 2000) return '-';

    final day = tanggal.day.toString().padLeft(2, '0');
    final month = tanggal.month.toString().padLeft(2, '0');
    final year = tanggal.year.toString();

    return "Selesai $day/$month/$year";
  }

  String _getNamaBarang(dynamic item) {
    return item['barang']?['nama_barang']?.toString() ??
        item['nama_barang']?.toString() ??
        '-';
  }

  String _getJumlah(dynamic item) {
    return item['jumlah']?.toString() ?? '1';
  }

  String _getKode(dynamic item) {
    return item['kode_peminjaman']?.toString() ??
        item['kode']?.toString() ??
        "#${item['id'] ?? '-'}";
  }

  String _getKondisiBarang(dynamic item) {
    final kondisi = item['kondisi_awal']?.toString() ??
        item['kondisi_barang']?.toString() ??
        item['kondisi_pinjam']?.toString() ??
        item['kondisi']?.toString() ??
        item['barang']?['kondisi_awal']?.toString() ??
        item['barang']?['kondisi_barang']?.toString() ??
        item['barang']?['kondisi']?.toString();

    if (kondisi == null || kondisi.trim().isEmpty || kondisi == 'null') {
      return 'Baik';
    }

    return kondisi;
  }

  String _getFotoBarang(dynamic item) {
    final foto = item['barang']?['foto_barang']?.toString() ??
        item['barang']?['gambar']?.toString() ??
        item['barang']?['image']?.toString() ??
        item['foto_barang']?.toString() ??
        item['gambar']?.toString() ??
        item['image']?.toString() ??
        '';

    if (foto.trim().isEmpty || foto == 'null') return '';

    if (foto.startsWith('http')) return foto;

    return "${AppConfig.baseUrl}/$foto";
  }

  Color _kondisiColor(String kondisi) {
    final text = kondisi.toLowerCase();

    if (text.contains('baik')) return Colors.green;
    if (text.contains('rusak')) return Colors.red;
    if (text.contains('hilang')) return Colors.orange;
    if (text.contains('tertunda')) return Colors.blueGrey;

    return primaryBlue;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildFilter(),
              const SizedBox(height: 6),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : filteredHistory.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: fetchHistory,
                            color: primaryBlue,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 18),
                              itemCount: filteredHistory.length,
                              itemBuilder: (context, index) {
                                return _buildHistoryCard(
                                  filteredHistory[index],
                                  index,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: textColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "History Peminjaman",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${filteredHistory.length} data selesai",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: fetchHistory,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: textColor,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _filterChip("semua", "Semua"),
            _filterChip("minggu", "Minggu Ini"),
            _filterChip("bulan", "Bulan Ini"),
            _filterChip("tahun", "Tahun Ini"),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final active = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => applyFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? (isDarkMode ? accentBlue.withOpacity(0.16) : primaryBlue)
                : cardColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active
                  ? (isDarkMode ? accentBlue : primaryBlue)
                  : borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? (isDarkMode ? accentBlue : Colors.white)
                  : subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarangImage(dynamic item) {
    final foto = _getFotoBarang(item);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDarkMode ? darkBg : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: foto.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2_rounded,
                    color: isDarkMode ? accentBlue : primaryBlue,
                    size: 31,
                  );
                },
              ),
            )
          : Icon(
              Icons.inventory_2_rounded,
              color: isDarkMode ? accentBlue : primaryBlue,
              size: 31,
            ),
    );
  }

  Widget _buildHistoryCard(dynamic item, int index) {
    final kondisi = _getKondisiBarang(item);
    final kondisiColor = _kondisiColor(kondisi);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.14 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarangImage(item),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getNamaBarang(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_getKode(item)} • Jumlah ${_getJumlah(item)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          "Selesai",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: kondisiColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          "Kondisi $kondisi",
                          style: TextStyle(
                            fontSize: 10,
                            color: kondisiColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 14,
                        color: subTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatTanggal(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.withOpacity(0.85),
              size: 25,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: fetchHistory,
      color: primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(
            Icons.history_toggle_off_rounded,
            size: 72,
            color: subTextColor.withOpacity(0.45),
          ),
          const SizedBox(height: 12),
          Text(
            "Belum ada history peminjaman",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
