import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'riwayat_peminjaman_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> activeNotifications = [];
  List<String> readIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      readIds = prefs.getStringList('read_notif_ids') ?? [];
    });
    _fetchNotifData();
  }

  Future<void> _markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList('read_notif_ids', readIds);
      setState(() {});
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatPeminjamanScreen(highlightId: id),
      ),
    );
  }

  Future<void> _fetchNotifData() async {
    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse("http://10.24.65.212:8000/api/v1/peminjaman"), 
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['data'];

        if (mounted) {
          setState(() {
            DateTime now = DateTime.now();

            // ==========================================
            // LOGIKA FILTER DEVI (SANGAT KETAT)
            // ==========================================
            activeNotifications = list.where((item) {
              // Ambil status, hapus spasi, dan jadikan huruf kecil
              String status = item['status'].toString().toLowerCase().trim();
              
              // 1. JALUR UTAMA (PENGEMBALIAN):
              // Jika mengandung kata 'kembali', lupakan aturan waktu, LANGSUNG TAMPILKAN.
              if (status.contains('kembali')) {
                return true; 
              }

              // 2. JALUR PERINGATAN (MASIH PINJAM):
              // Cek apakah statusnya sedang dipinjam atau dikonfirmasi admin
              if (status.contains('pinjam') || status.contains('konfirmasi')) {
                if (item['created_at'] == null) return false;

                DateTime tglPinjam = DateTime.parse(item['created_at']).toLocal();
                Duration selisih = now.difference(tglPinjam);

  
                return selisih.inHours >= 8; 
              }

              return false;
            }).toList();

            // Urutkan yang terbaru (ID terbesar) di atas
            activeNotifications.sort((a, b) => b['id'].compareTo(a['id']));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Fetch Data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Pusat Notifikasi"),
        backgroundColor: const Color(0xFF1d3557),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync), 
            onPressed: _fetchNotifData,
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : activeNotifications.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                  child: Text(
                    "Belum ada pemberitahuan baru.\n(Peringatan muncul jika barang belum dikembalikan)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  )
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: activeNotifications.length,
              itemBuilder: (context, index) {
                final item = activeNotifications[index];
                final String itemId = item['id'].toString();
                
                final String statusRaw = item['status'].toString().toLowerCase();
                final bool isSelesai = statusRaw.contains('kembali');

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    // Warna hijau jika kembali, warna amber/kuning jika peringatan
                    color: isSelesai ? Colors.green[50] : Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelesai ? Colors.green[200]! : Colors.amber[200]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isSelesai ? Colors.green : Colors.amber[700],
                      child: Icon(
                        isSelesai ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      isSelesai ? "PENGEMBALIAN BERHASIL" : "PERINGATAN PEMINJAMAN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelesai ? Colors.green[900] : Colors.amber[900],
                      ),
                    ),
                      subtitle: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Text(
                          "Barang: ${item['barang']['nama_barang']}\n"
                          "${isSelesai 
                              ? 'Barang telah sukses diterima kembali oleh Admin.' 
                              : 'Status barang masih dipinjam. Harap segera dikembalikan.'}",
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ),
                    onTap: () => _markAsRead(itemId),
                  ),
                );
              },
            ),
    );
  }
}