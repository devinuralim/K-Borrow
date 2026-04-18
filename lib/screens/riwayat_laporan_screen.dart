import 'package:flutter/material.dart';
import '../models/laporan_model.dart';
import '../services/laporan_service.dart';

const Color primaryNavy = Color(0xFF1d3557);
const Color dangerRed = Color(0xFFb91c1c);
const Color infoBlue = Color(0xFF3b82f6);

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  State<RiwayatLaporanScreen> createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  
  Future<void> _handleRefresh() async {
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu': return Colors.orange.shade800;
      case 'proses': return Colors.blue.shade700;
      case 'selesai': return Colors.green.shade700;
      case 'ditolak': return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'rusak': return dangerRed;
      case 'hilang': return Colors.grey.shade600;
      case 'tertinggal': return infoBlue;
      default: return Colors.black87;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu': return Icons.hourglass_empty_rounded;
      case 'proses': return Icons.sync_rounded;
      case 'selesai': return Icons.check_circle_rounded;
      case 'ditolak': return Icons.cancel_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Riwayat Laporan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleRefresh,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: const BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: const Text(
              "Pantau status perbaikan, penggantian, atau penemuan barang yang dilaporkan secara real-time.",
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: FutureBuilder<List<LaporanModel>>(
              future: LaporanService.getLaporan(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryNavy));
                }
                
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) return _buildEmptyState(isDark);

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: primaryNavy,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final statusColor = _getStatusColor(item.status);
                      final jenisColor = _getJenisColor(item.jenisLaporan);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  _buildIconContainer(isDark),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.namaBarang,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 15,
                                            color: isDark ? Colors.white : Colors.black87
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        _buildStatusBadge(item.status, statusColor),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "#${item.id}",
                                    style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 16, endIndent: 16),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(Icons.error_outline, "Jenis", item.jenisLaporan, jenisColor, isDark),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.calendar_month_outlined, "Tanggal", item.tanggal?.substring(0, 10) ?? "-", isDark ? Colors.white70 : Colors.black87, isDark),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.inventory_2_outlined, "Jumlah", "${item.jumlah} Unit", isDark ? Colors.white70 : Colors.black87, isDark),
                                  
                                  if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black12 : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                                      ),
                                      child: Text(
                                        "\"${item.keterangan}\"",
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ]
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

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.assignment_late_outlined, color: isDark ? Colors.white70 : primaryNavy, size: 24),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white30 : Colors.grey),
        const SizedBox(width: 8),
        Text("$label:", style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
        const Spacer(),
        Text(
          value.isNotEmpty ? value[0].toUpperCase() + value.substring(1) : "-",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum Ada Riwayat", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
          Text("Laporan yang Anda buat akan muncul di sini.", style: TextStyle(color: isDark ? Colors.white30 : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: dangerRed),
            const SizedBox(height: 10),
            const Text("Gagal memuat data", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            TextButton(onPressed: _handleRefresh, child: const Text("Coba Lagi"))
          ],
        ),
      ),
    );
  }
}