import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import 'pengajuan_screen.dart';
import 'barang_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

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
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 900),
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

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    final items = widget.semuaBarang
        .where((barang) => localKeranjang.containsKey(barang.id))
        .toList();

    int totalJumlah = 0;
    for (final item in items) {
      totalJumlah += localKeranjang[item.id] ?? 0;
    }

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
              _buildHeader(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
                itemCount: items.length,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(isDark, subTextColor)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final barang = items[index];
                          final jumlah = localKeranjang[barang.id] ?? 0;

                          return _buildCartItem(
                            barang: barang,
                            jumlah: jumlah,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildBottomButton(
              isDark: isDark,
              items: items,
              totalJumlah: totalJumlah,
            ),
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required int itemCount,
  }) {
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
                  "Keranjang",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "$itemCount barang dipilih",
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BarangScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem({
    required BarangModel barang,
    required int jumlah,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark ? darkBg : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: barang.fotoBarang != null && barang.fotoBarang!.isNotEmpty
                  ? Image.network(
                      barang.fotoBarang!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.inventory_2_rounded,
                          color: isDark ? accentBlue : primaryBlue,
                          size: 32,
                        );
                      },
                    )
                  : Icon(
                      Icons.inventory_2_rounded,
                      color: isDark ? accentBlue : primaryBlue,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barang.namaBarang,
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
                  "SN: ${barang.seri ?? '-'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: barang.stok <= 0
                        ? Colors.red.withOpacity(0.10)
                        : Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    barang.stok <= 0
                        ? "Habis"
                        : "Stok tersedia ${barang.stok}",
                    style: TextStyle(
                      color: barang.stok <= 0 ? Colors.red : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _qtyButton(
                icon: Icons.add_rounded,
                color: jumlah >= barang.stok ? Colors.grey : primaryBlue,
                onTap:
                    jumlah >= barang.stok ? null : () => _tambahJumlah(barang),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  "$jumlah",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _qtyButton(
                icon: Icons.remove_rounded,
                color: Colors.red,
                onTap: () => _kurangJumlah(barang),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required bool isDark,
    required List<BarangModel> items,
    required int totalJumlah,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Lanjutkan Pengajuan ($totalJumlah)",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 78,
            color: subTextColor.withOpacity(0.45),
          ),
          const SizedBox(height: 14),
          Text(
            "Keranjang masih kosong",
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tambahkan barang untuk membuat peminjaman.",
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
}