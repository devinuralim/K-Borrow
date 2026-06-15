import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';
import 'kondisi_barang_screen.dart';
import 'upload_tindak_lanjut_screen.dart';

const Color primaryNavy = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class RiwayatPeminjamanScreen extends StatefulWidget {
  final String? highlightId;

  const RiwayatPeminjamanScreen({super.key, this.highlightId});

  State<RiwayatPeminjamanScreen> createState() {
    return _RiwayatPeminjamanScreenState();
  }
}

class _RiwayatPeminjamanScreenState extends State<RiwayatPeminjamanScreen> {
  late Future<List<PeminjamanModel>> _futurePeminjaman;

  bool isSelectionMode = false;

  final List<int> selectedIds = [];
  final List<PeminjamanModel> selectedItems = [];

  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futurePeminjaman = PeminjamanService.getPeminjaman();
    });
  }

  void _toggleSelect(PeminjamanModel item) {
    final id = item.id;

    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
        selectedItems.removeWhere((e) => e.id == id);
      } else {
        selectedIds.add(id);
        selectedItems.add(item);
      }

      isSelectionMode = selectedIds.isNotEmpty;
    });
  }

  Future<bool> _confirmCancelSelection() async {
    if (!isSelectionMode || selectedIds.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Batalkan pengembalian?",
            style: TextStyle(
              color: isDark ? Colors.white : primaryNavy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            "Kamu sudah memilih ${selectedIds.length} barang. Kalau keluar sekarang, pilihan akan dibatalkan.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Lanjut pilih",
                style: TextStyle(
                  color: isDark ? accentBlue : primaryNavy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedIds.clear();
                  selectedItems.clear();
                  isSelectionMode = false;
                });

                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Ya, batalkan",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  bool _bolehTampil(PeminjamanModel item) {
    final status = item.status.toLowerCase();

    if (status == 'selesai') return false;

    if (status == 'digunakan') {
      final durasi = DateTime.now().difference(item.tanggalPinjam.toLocal());
      return durasi.inHours < 8;
    }

    return true;
  }

  bool _canSelect(String status) {
    return status == 'dipinjam' || status == 'ditolak';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'dipinjam':
        return 'DIPINJAM';
      case 'digunakan':
        return 'DIGUNAKAN';
      case 'menunggu_konfirmasi_pengembalian':
        return 'MENUNGGU KONFIRMASI';
      case 'menunggu_perbaikan':
        return 'MENUNGGU PERBAIKAN';
      case 'menunggu_verifikasi_perbaikan':
        return 'VERIFIKASI PERBAIKAN';
      case 'menunggu_ganti_rugi':
        return 'MENUNGGU BAYAR';
      case 'menunggu_verifikasi_ganti_rugi':
        return 'VERIFIKASI BAYAR';
      case 'menunggu_ganti_barang':
        return 'MENUNGGU BARANG';
      case 'menunggu_verifikasi_ganti_barang':
        return 'VERIFIKASI BARANG';
      case 'menunggu_perpanjangan':
        return 'MENUNGGU PERPANJANGAN';
      case 'ditolak':
        return 'DITOLAK';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'dipinjam':
        return isDark ? Colors.orangeAccent : Colors.orange.shade800;
      case 'digunakan':
        return isDark ? Colors.cyanAccent : Colors.cyan.shade700;
      case 'menunggu_konfirmasi_pengembalian':
        return isDark ? Colors.blueAccent : Colors.blue.shade700;
      case 'menunggu_perbaikan':
        return isDark ? Colors.amberAccent : Colors.amber.shade800;
      case 'menunggu_verifikasi_perbaikan':
        return isDark ? Colors.greenAccent : Colors.green.shade700;
      case 'menunggu_ganti_rugi':
        return isDark ? Colors.redAccent : Colors.red.shade700;
      case 'menunggu_verifikasi_ganti_rugi':
        return isDark ? Colors.greenAccent : Colors.green.shade700;
      case 'menunggu_ganti_barang':
        return isDark ? Colors.purpleAccent : Colors.purple.shade700;
      case 'menunggu_verifikasi_ganti_barang':
        return isDark ? Colors.greenAccent : Colors.green.shade700;
      case 'menunggu_perpanjangan':
        return isDark ? Colors.indigoAccent : Colors.indigo.shade700;
      case 'ditolak':
        return isDark ? Colors.redAccent : Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openTindakLanjut({
    required PeminjamanModel item,
    required String tipe,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadTindakLanjutScreen(
          peminjaman: item,
          tipe: tipe,
        ),
      ),
    );

    if (result == true) _loadData();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildActionByStatus(PeminjamanModel item, String status) {
    if (status == 'dipinjam' || status == 'ditolak') {
      return _buildActionButton(
        icon: Icons.assignment_return_rounded,
        label: 'KEMBALIKAN',
        color: Colors.green.shade600,
        onPressed: () async {
          final bool wajibBaik = status == 'ditolak' ||
              (item.keteranganTindakLanjut ?? '')
                  .toLowerCase()
                  .contains('ditolak');

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KondisiBarangScreen(
                peminjaman: item,
                forceKondisi: wajibBaik ? 'baik' : null,
              ),
            ),
          );

          if (result == true) _loadData();
        },
      );
    }

    if (status == 'menunggu_perbaikan') {
      return _buildActionButton(
        icon: Icons.build_circle_rounded,
        label: 'PERBAIKAN',
        color: Colors.orange.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'perbaikan');
        },
      );
    }

    if (status == 'menunggu_ganti_rugi') {
      return _buildActionButton(
        icon: Icons.payments_rounded,
        label: 'BAYAR',
        color: Colors.red.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'ganti_rugi');
        },
      );
    }

    if (status == 'menunggu_ganti_barang') {
      return _buildActionButton(
        icon: Icons.inventory_rounded,
        label: 'BARANG',
        color: Colors.purple.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'ganti_barang');
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTanggalInfo(PeminjamanModel item, bool isDark) {
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: subTextColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(item.tanggalPinjam.toLocal()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: subTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (item.tanggalKembali != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 13,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Batas kembali: ${DateFormat('dd MMM yyyy').format(item.tanggalKembali!.toLocal())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (item.keteranganTindakLanjut != null &&
            item.keteranganTindakLanjut!.isNotEmpty) ...[
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.20)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 15,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Perpanjangan ditolak admin. Segera kembalikan barang.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryNavy;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return WillPopScope(
      onWillPop: _confirmCancelSelection,
      child: Scaffold(
        backgroundColor: bgColor,
        bottomNavigationBar: isSelectionMode
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(
                      top: BorderSide(color: borderColor),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KondisiBarangScreen(
                                  peminjamanIds: List<int>.from(selectedIds),
                                  selectedItems: List<PeminjamanModel>.from(
                                    selectedItems,
                                  ),
                                ),
                              ),
                            );

                            if (result == true) {
                              setState(() {
                                selectedIds.clear();
                                selectedItems.clear();
                                isSelectionMode = false;
                              });

                              _loadData();
                            }
                          },
                    icon: const Icon(Icons.assignment_return_rounded),
                    label: Text(
                      'Kembalikan ${selectedIds.length} Barang Dipilih',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              )
            : null,
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
                _buildHeader(
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
                if (!isSelectionMode)
                  _buildInfoSelect(subTextColor, cardColor, borderColor),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<PeminjamanModel>>(
                    future: _futurePeminjaman,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: isDark ? accentBlue : primaryNavy,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildCenterMessage(
                          icon: Icons.error_outline_rounded,
                          title: "Gagal memuat data",
                          subtitle: "Tarik ke bawah atau tekan refresh.",
                          subTextColor: subTextColor,
                          textColor: textColor,
                        );
                      }

                      final data = (snapshot.data ?? [])
                          .where(_bolehTampil)
                          .toList()
                        ..sort(
                          (a, b) => b.tanggalPinjam.compareTo(a.tanggalPinjam),
                        );

                      if (data.isEmpty) {
                        return _buildEmptyState(
                          isDark,
                          textColor,
                          subTextColor,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        color: primaryNavy,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            final status = item.status.toLowerCase();
                            final statusColor = _getStatusColor(status, isDark);
                            final isHighlighted =
                                widget.highlightId == item.id.toString();
                            final canSelect = _canSelect(status);
                            final isSelected = selectedIds.contains(item.id);

                            return GestureDetector(
                              onTap: () {
                                if (canSelect) {
                                  _toggleSelect(item);
                                }
                              },
                              child: _buildHistoryCard(
                                item: item,
                                status: status,
                                statusColor: statusColor,
                                isHighlighted: isHighlighted,
                                isSelected: isSelected,
                                canSelect: canSelect,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                borderColor: borderColor,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSelect(
      Color subTextColor, Color cardColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
    );
  }

  Widget _buildHeader({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              final bolehKeluar = await _confirmCancelSelection();

              if (!mounted) return;

              if (bolehKeluar) {
                Navigator.pop(context);
              }
            },
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
                  "Riwayat Peminjaman",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSelectionMode
                      ? "${selectedIds.length} barang dipilih"
                      : "Pilih barang yang ingin dikembalikan",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isSelectionMode)
            InkWell(
              onTap: () {
                setState(() {
                  selectedIds.clear();
                  selectedItems.clear();
                  isSelectionMode = false;
                });
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                  size: 23,
                ),
              ),
            )
          else
            InkWell(
              onTap: _loadData,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryNavy, secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryNavy.withOpacity(0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required PeminjamanModel item,
    required String status,
    required Color statusColor,
    required bool isHighlighted,
    required bool isSelected,
    required bool canSelect,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryNavy.withOpacity(isDark ? 0.30 : 0.08)
            : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? primaryNavy
              : isHighlighted
                  ? Colors.orange
                  : canSelect
                      ? primaryNavy.withOpacity(0.22)
                      : borderColor,
          width: isSelected || isHighlighted ? 1.7 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSelectCircle(
                isSelected: isSelected,
                canSelect: canSelect,
                subTextColor: subTextColor,
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.orange.withOpacity(0.12)
                      : isDark
                          ? darkBg
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  isHighlighted
                      ? Icons.star_rounded
                      : Icons.inventory_2_rounded,
                  color: isHighlighted
                      ? Colors.orange
                      : isDark
                          ? accentBlue
                          : primaryNavy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.barang?.namaBarang ?? 'Barang Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 Unit • Tap untuk pilih',
                      style: TextStyle(
                        color: canSelect ? primaryNavy : subTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 118),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _formatStatus(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildTanggalInfo(item, isDark),
              ),
              const SizedBox(width: 8),
              isSelectionMode
                  ? const SizedBox.shrink()
                  : _buildActionByStatus(item, status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCircle({
    required bool isSelected,
    required bool canSelect,
    required Color subTextColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? primaryNavy : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? primaryNavy
              : canSelect
                  ? primaryNavy.withOpacity(0.55)
                  : subTextColor.withOpacity(0.20),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
            )
          : Icon(
              Icons.add_rounded,
              color: canSelect
                  ? primaryNavy.withOpacity(0.65)
                  : Colors.transparent,
              size: 18,
            ),
    );
  }

  Widget _buildCenterMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color subTextColor,
    required Color textColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 74, color: subTextColor.withOpacity(0.45)),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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

  Widget _buildEmptyState(
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return _buildCenterMessage(
      icon: Icons.history_rounded,
      title: "Belum ada riwayat peminjaman",
      subtitle: "Semua peminjaman aktif akan muncul di sini.",
      textColor: textColor,
      subTextColor: subTextColor,
    );
  }
}
