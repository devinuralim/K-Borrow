import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/barang_service.dart';
import '../services/favorit_service.dart';

// Variabel warna tema agar konsisten
const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF1F4F8);

class BarangScreen extends StatefulWidget {
  const BarangScreen({super.key});

  @override
  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> {
  List<BarangModel> allBarang = [];
  List<BarangModel> filteredBarang = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  Future<void> _fetchBarang() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final data = await BarangService.getBarang();
    setState(() {
      allBarang = data;
      filteredBarang = data;
      isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      filteredBarang = allBarang
          .where((b) => b.namaBarang.toLowerCase().contains(query.toLowerCase()) ||
                        (b.seri?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _toggleFav(BarangModel barang) async {
    setState(() => barang.isFavorit = !barang.isFavorit);
    final res = await FavoritService.toggleFavorit(barang.id);
    if (res == null || res['success'] != true) {
      setState(() => barang.isFavorit = !barang.isFavorit);
    }
  }

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      title: const Text("Daftar Barang",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Column(
      children: [
        // HEADER SEARCH
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          decoration: const BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: TextField(
            onChanged: _onSearch,
            // Agar teks input tetap terlihat jelas
            style: const TextStyle(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              hintText: "Cari nama barang...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // LIST BARANG
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryBlue))
              : RefreshIndicator(
                  onRefresh: _fetchBarang,
                  color: primaryBlue,
                  child: filteredBarang.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredBarang.length,
                          itemBuilder: (context, index) {
                            final item = filteredBarang[index];
                            bool isKosong = item.stok <= 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                               BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
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
                                      item.namaBarang,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : primaryBlue,
                                          fontSize: 15),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "SN: ${item.seri ?? '-'}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.black54),
                                      ),
                                    ),
                                    // Tombol Favorit yang sempat hilang
                                    trailing: IconButton(
                                      icon: Icon(
                                        item.isFavorit ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: item.isFavorit ? Colors.amber : Colors.grey,
                                        size: 28,
                                      ),
                                      onPressed: () => _toggleFav(item),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Label Jenis
                                        Row(
                                          children: [
                                            const Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 5),
                                            Text(
                                              item.jenisBarang,
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        // Badge Stok
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isKosong
                                                ? Colors.red.withValues(alpha: 0.15)
                                                : (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F5E9)),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isKosong ? "STOK HABIS" : "STOK: ${item.stok}",
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
                ),
        ),
      ],
    ),
  );
}
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Barang tidak ditemukan", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}