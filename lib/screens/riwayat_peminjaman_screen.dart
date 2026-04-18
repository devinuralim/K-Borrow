import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';
import 'pengembalian_barang_screen.dart';

// Variabel warna branding tetap
const Color primaryNavy = Color(0xFF1d3557);

class RiwayatPeminjamanScreen extends StatefulWidget {
  final String? highlightId;

  const RiwayatPeminjamanScreen({super.key, this.highlightId});

  @override
  State<RiwayatPeminjamanScreen> createState() => _RiwayatPeminjamanScreenState();
}

class _RiwayatPeminjamanScreenState extends State<RiwayatPeminjamanScreen> {
  late Future<List<PeminjamanModel>> _futurePeminjaman;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futurePeminjaman = PeminjamanService.getPeminjaman();
    });
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'dipinjam': return isDark ? Colors.orangeAccent : Colors.orange.shade800;
      case 'dikembalikan': return isDark ? Colors.greenAccent : Colors.green.shade700;
      case 'menunggu konfirmasi': return isDark ? Colors.blueAccent : Colors.blue.shade700;
      case 'ditolak': return isDark ? Colors.redAccent : Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Riwayat Peminjaman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          )
        ],
      ),
      body: Column(
        children: [
          // Header Biru Melengkung
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
              "Pantau status peminjaman barang inventaris Anda di sini.",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: FutureBuilder<List<PeminjamanModel>>(
              future: _futurePeminjaman,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryNavy));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Gagal memuat data", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)));
                }

                final data = snapshot.data ?? [];
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
                      final bool isHighlighted = widget.highlightId == item.id.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isHighlighted 
                            ? Border.all(color: Colors.orange.shade400, width: 2) 
                            : null,
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isHighlighted 
                                      ? Colors.orange.withOpacity(0.1) 
                                      : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F4F8)),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  isHighlighted ? Icons.star_rounded : Icons.inventory_2_rounded, 
                                  color: isHighlighted ? Colors.orange : (isDark ? Colors.blue[200] : primaryNavy), 
                                  size: 24
                                ),
                              ),
                              title: Text(
                                item.barang?.namaBarang ?? "Barang Unknown",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 15,
                                  color: isDark ? Colors.white : primaryNavy,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Jumlah: ${item.jumlah} Unit", 
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 15, endIndent: 15),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(item.tanggalPinjam),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  if (status == 'dipinjam')
                                    SizedBox(
                                      height: 34,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PengembalianBarangScreen(peminjaman: item),
                                            ),
                                          );
                                          if (result == true) _loadData();
                                        },
                                        icon: const Icon(Icons.assignment_return_rounded, size: 14),
                                        label: const Text("KEMBALIKAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? Colors.green[700] : Colors.green[600],
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                    ),
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
          Icon(Icons.history_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "Belum ada riwayat peminjaman",
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            "Semua aktivitas peminjaman barang Anda\nakan muncul di sini.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}