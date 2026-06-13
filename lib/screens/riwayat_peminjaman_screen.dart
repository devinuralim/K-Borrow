import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';
import 'kondisi_barang_screen.dart';
import 'upload_tindak_lanjut_screen.dart';

const Color primaryNavy = Color(0xFF1d3557);

class RiwayatPeminjamanScreen extends StatefulWidget {
  final String? highlightId;

  const RiwayatPeminjamanScreen({super.key, this.highlightId});

  State<RiwayatPeminjamanScreen> createState() =>
      _RiwayatPeminjamanScreenState();
}

class _RiwayatPeminjamanScreenState extends State<RiwayatPeminjamanScreen> {
  late Future<List<PeminjamanModel>> _futurePeminjaman;

  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futurePeminjaman = PeminjamanService.getPeminjaman();
    });
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Future<void> _openTindakLanjut({
    required PeminjamanModel item,
    required String tipe,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadTindakLanjutScreen(peminjaman: item, tipe: tipe),
      ),
    );

    if (result == true) _loadData();
  }

  Widget _buildActionByStatus(PeminjamanModel item, String status) {
    if (status == 'dipinjam' || status == 'ditolak') {
      return _buildActionButton(
        icon: Icons.assignment_return_rounded,
        label: status == 'ditolak' ? 'KEMBALIKAN' : 'KEMBALIKAN',
        color: Colors.green.shade600,
        onPressed: () async {
          final bool wajibBaik =
              status == 'ditolak' ||
              (item.keteranganTindakLanjut ?? '').toLowerCase().contains(
                'ditolak',
              );

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
        label: 'UPLOAD PERBAIKAN',
        color: Colors.orange.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'perbaikan');
        },
      );
    }

    if (status == 'menunggu_ganti_rugi') {
      return _buildActionButton(
        icon: Icons.payments_rounded,
        label: 'UPLOAD BAYAR',
        color: Colors.red.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'ganti_rugi');
        },
      );
    }

    if (status == 'menunggu_ganti_barang') {
      return _buildActionButton(
        icon: Icons.inventory_rounded,
        label: 'UPLOAD BARANG',
        color: Colors.purple.shade700,
        onPressed: () {
          _openTindakLanjut(item: item, tipe: 'ganti_barang');
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTanggalInfo(PeminjamanModel item, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(item.tanggalPinjam.toLocal()),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),

        if (item.tanggalKembali != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                'Batas kembali: ${DateFormat('dd MMM yyyy').format(item.tanggalKembali!.toLocal())}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],

        if (item.keteranganTindakLanjut != null &&
            item.keteranganTindakLanjut!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perpanjangan ditolak admin. Segera kembalikan barang.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Peminjaman',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
            decoration: const BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: const Text(
              'Pantau status peminjaman barang inventaris Anda di sini.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PeminjamanModel>>(
              future: _futurePeminjaman,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryNavy),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  );
                }

                final data = (snapshot.data ?? []).where(_bolehTampil).toList()
                  ..sort((a, b) => b.tanggalPinjam.compareTo(a.tanggalPinjam));

                if (data.isEmpty) return _buildEmptyState(isDark);

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: primaryNavy,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final status = item.status.toLowerCase();
                      final statusColor = _getStatusColor(status, isDark);
                      final isHighlighted =
                          widget.highlightId == item.id.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isHighlighted
                              ? Border.all(
                                  color: Colors.orange.shade400,
                                  width: 2,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? Colors.orange.withOpacity(0.1)
                                      : isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : const Color(0xFFF1F4F8),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  isHighlighted
                                      ? Icons.star_rounded
                                      : Icons.inventory_2_rounded,
                                  color: isHighlighted
                                      ? Colors.orange
                                      : isDark
                                      ? Colors.blue[200]
                                      : primaryNavy,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                item.barang?.namaBarang ?? 'Barang Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : primaryNavy,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Jumlah: ${item.jumlah} Unit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatStatus(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : Colors.black12,
                              indent: 15,
                              endIndent: 15,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildTanggalInfo(item, status),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildActionByStatus(item, status),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.grey[300],
          ),
          const SizedBox(height: 15),
          Text(
            'Belum ada riwayat peminjaman',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Semua aktivitas peminjaman aktif Anda\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white30 : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
