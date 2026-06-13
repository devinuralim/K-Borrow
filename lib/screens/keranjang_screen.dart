import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import 'pengajuan_screen.dart';
import 'barang_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF1F4F8);

class KeranjangScreen extends StatefulWidget {
  final Map<int, int> keranjang;
  final List<BarangModel> semuaBarang;
  const KeranjangScreen({
    super.key,
    required this.keranjang,
    required this.semuaBarang,
  });

  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  late Map<int, int> localKeranjang;

  void initState() {
    super.initState();
    localKeranjang = Map<int, int>.from(widget.keranjang);
  }

  void _tambahJumlah(BarangModel barang) {
    final jumlahSekarang = localKeranjang[barang.id] ?? 0;
    if (jumlahSekarang >= barang.stok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Jumlah melebihi stok yang tersedia!"),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }
    setState(() {
      localKeranjang[barang.id] = jumlahSekarang + 1;
      widget.keranjang[barang.id] = localKeranjang[barang.id]!;
    });
  }

  void _kurangJumlah(BarangModel barang) {
    final jumlahSekarang = localKeranjang[barang.id] ?? 0;
    if (jumlahSekarang <= 0) return;
    setState(() {
      if (jumlahSekarang > 1) {
        localKeranjang[barang.id] = jumlahSekarang - 1;
        widget.keranjang[barang.id] = localKeranjang[barang.id]!;
      } else {
        localKeranjang.remove(barang.id);
        widget.keranjang.remove(barang.id);
      }
    });
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.semuaBarang
        .where((barang) => localKeranjang.containsKey(barang.id))
        .toList();
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : backgroundGray,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          "Keranjang Peminjaman",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: "Tambah Barang",
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BarangScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 15,
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
            child: items.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final barang = items[index];
                      final jumlah = localKeranjang[barang.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.04,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFF1F4F8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: barang.fotoBarang != null &&
                                          barang.fotoBarang!.isNotEmpty
                                      ? Image.network(
                                          barang.fotoBarang!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image_not_supported_rounded,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.inventory_2_rounded,
                                          color: primaryBlue,
                                          size: 30,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barang.namaBarang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color:
                                            isDark ? Colors.white : primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "SN: ${barang.seri ?? '-'}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Stok Tersedia: ${barang.stok}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: barang.stok <= 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _kurangJumlah(barang),
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                    ),
                                    color: secondaryBlue,
                                    iconSize: 22,
                                  ),
                                  Text(
                                    "$jumlah",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: jumlah >= barang.stok
                                        ? null
                                        : () => _tambahJumlah(barang),
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    color: secondaryBlue,
                                    iconSize: 22,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PengajuanScreen(
                        keranjang: localKeranjang,
                        semuaBarang: widget.semuaBarang,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Ajukan Peminjaman (${items.length} Barang)",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: isDark ? Colors.white10 : Colors.grey[300],
          ),
          const SizedBox(height: 15),
          Text(
            "Keranjang masih kosong",
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
