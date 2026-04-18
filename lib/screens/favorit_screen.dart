import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/favorit_service.dart';

// Variabel warna tema tetap ada untuk branding biru
const Color primaryBlue = Color(0xFF1d3557);

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  late Future<List<BarangModel>> futureFavorit;

  @override
  void initState() {
    super.initState();
    _loadFavorit();
  }

  void _loadFavorit() {
    setState(() {
      futureFavorit = FavoritService.getFavorit();
    });
  }

  void _toggleFavorit(BarangModel barang) async {
    final response = await FavoritService.toggleFavorit(barang.id);

    if (response != null && response['success'] == true) {
      _loadFavorit(); // Refresh list
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Berhasil memperbarui favorit"),
          backgroundColor: primaryBlue,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengubah favorit"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi mode gelap
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 1. Gunakan warna background dari tema global
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text("Barang Favorit",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header biru melengkung (tetap biru untuk branding)
          Container(
            height: 20,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BarangModel>>(
              future: futureFavorit,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryBlue));
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Terjadi error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.grey)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                final barangs = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => _loadFavorit(),
                  color: primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: barangs.length,
                    itemBuilder: (context, index) {
                      final barang = barangs[index];
                      barang.isFavorit = true; 
                      bool isKosong = barang.stok <= 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          // 2. Gunakan warna card dari tema global
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  // 3. Warna background icon adaptif
                                  color: isKosong
                                     ? Colors.red.withValues(alpha: 0.1)
                                      : (isDark ? Colors.white10 : const Color(0xFFF1F4F8)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isKosong ? Colors.red : (isDark ? Colors.blue[200] : primaryBlue),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                barang.namaBarang,
                                // 4. Warna teks adaptif
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : primaryBlue,
                                    fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "SN: ${barang.seri ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.black54),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                                onPressed: () => _toggleFavorit(barang),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.category_outlined,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        barang.jenisBarang,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  // 5. Badge stok adaptif
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isKosong
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F5E9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isKosong ? "STOK HABIS" : "STOK: ${barang.stok}",
                                      style: TextStyle(
                                        color: isKosong ? Colors.redAccent : (isDark ? Colors.green[300] : Colors.green[700]),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
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
          Icon(Icons.star_border_rounded, 
               size: 80, 
               color: isDark ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "Belum ada barang favorit",
            style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey, 
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            "Klik ikon bintang pada daftar barang\nuntuk menambahkan ke sini.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400], 
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}