import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/barang_service.dart';
import '../services/favorit_service.dart';
import 'keranjang_screen.dart';
import '../services/cart_service.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF1F4F8);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);

class BarangScreen extends StatefulWidget {
  const BarangScreen({super.key});

  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> {
  List<BarangModel> allBarang = [];
  List<BarangModel> filteredBarang = [];
  bool isLoading = true;
  Map<int, int> keranjang = {};
  bool animasiKeranjang = false;

  int get totalItemDiKeranjang => CartService.totalItem;

  void tambahBarang(BarangModel barang) {
    setState(() {
      CartService.tambahBarang(barang);
      keranjang[barang.id] = CartService.getJumlah(barang.id);
      animasiKeranjang = true;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => animasiKeranjang = false);
    });
  }

  void kurangBarang(BarangModel barang) {
    setState(() {
      CartService.kurangBarang(barang);

      if (CartService.getJumlah(barang.id) == 0) {
        keranjang.remove(barang.id);
      } else {
        keranjang[barang.id] = CartService.getJumlah(barang.id);
      }
    });
  }

  void initState() {
    super.initState();
    keranjang = Map<int, int>.from(CartService.keranjang);
    _fetchBarang();
  }

  Future<void> _fetchBarang() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final data = await BarangService.getBarang();

    if (!mounted) return;

    setState(() {
      allBarang = data;
      filteredBarang = data;
      isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      filteredBarang = allBarang
          .where(
            (b) =>
                b.namaBarang.toLowerCase().contains(query.toLowerCase()) ||
                (b.seri?.toLowerCase().contains(query.toLowerCase()) ?? false),
          )
          .toList();
    });
  }

  void _toggleFav(BarangModel barang) async {
    setState(() => barang.isFavorit = !barang.isFavorit);

    final res = await FavoritService.toggleFavorit(barang.id);

    if (res == null || res['success'] != true) {
      if (!mounted) return;
      setState(() => barang.isFavorit = !barang.isFavorit);
    }
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Katalog Barang",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildCartIcon(),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: _onSearch,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Cari barang...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    filled: true,
                    fillColor: isDark ? darkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  )
                : filteredBarang.isEmpty
                ? Center(
                    child: Text(
                      "Barang tidak ditemukan",
                      style: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filteredBarang.length,
                    itemBuilder: (context, index) {
                      return _buildGridItem(
                        filteredBarang[index],
                        cardColor,
                        textColor,
                        subTextColor,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KeranjangScreen(
            keranjang: CartService.keranjang,
            semuaBarang: CartService.semuaBarang,
          ),
        ),
      ),
      child: AnimatedScale(
        scale: animasiKeranjang ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 26,
            ),
            if (totalItemDiKeranjang > 0)
              Positioned(
                right: -7,
                top: -7,
                child: AnimatedScale(
                  scale: animasiKeranjang ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$totalItemDiKeranjang',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BarangModel item,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final bool isKosong = item.stok <= 0;
    final int jumlah = CartService.getJumlah(item.id);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: item.fotoBarang != null && item.fotoBarang!.isNotEmpty
                      ? Image.network(
                          item.fotoBarang!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.inventory_2,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFav(item),
                    child: Icon(
                      item.isFavorit ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBarang,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "SN: ${item.seri ?? '-'}",
                  style: TextStyle(fontSize: 10, color: subTextColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isKosong ? "Habis" : "Stok: ${item.stok}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isKosong ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (jumlah > 0) ...[
                          GestureDetector(
                            onTap: () => kurangBarang(item),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              size: 28,
                              color: Colors.red,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$jumlah',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                        GestureDetector(
                          onTap: isKosong || jumlah >= item.stok
                              ? null
                              : () => tambahBarang(item),
                          child: Icon(
                            Icons.add_circle,
                            size: 30,
                            color: isKosong
                                ? Colors.grey
                                : isDark
                                ? Colors.cyanAccent
                                : primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
