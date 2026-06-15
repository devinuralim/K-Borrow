import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/favorit_service.dart';
import 'keranjang_screen.dart';
import '../services/cart_service.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  final GlobalKey _cartKey = GlobalKey();

  late Future<List<BarangModel>> futureFavorit;
  List<BarangModel> allFavorit = [];
  List<BarangModel> filteredFavorit = [];
  Map<int, int> keranjang = {};
  bool animasiKeranjang = false;

  int get totalItemDiKeranjang => CartService.totalItem;

  void initState() {
    super.initState();
    keranjang = Map<int, int>.from(CartService.keranjang);
    _loadFavorit();
  }

  void _loadFavorit() {
    futureFavorit = FavoritService.getFavorit();
  }

  Future<void> _refreshFavorit() async {
    setState(() {
      allFavorit.clear();
      filteredFavorit.clear();
      _loadFavorit();
    });
  }

  void tambahBarang(BarangModel barang, GlobalKey buttonKey) {
    _flyToCart(buttonKey);

    setState(() {
      CartService.tambahBarang(barang);
      keranjang[barang.id] = CartService.getJumlah(barang.id);
      animasiKeranjang = true;
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => animasiKeranjang = false);
    });
  }

  void _flyToCart(GlobalKey startKey) {
    final startContext = startKey.currentContext;
    final cartContext = _cartKey.currentContext;

    if (startContext == null || cartContext == null) return;

    final startBox = startContext.findRenderObject() as RenderBox;
    final cartBox = cartContext.findRenderObject() as RenderBox;

    final startPosition = startBox.localToGlobal(Offset.zero);
    final cartPosition = cartBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _FlyingCartAnimation(
          start: Offset(
            startPosition.dx + startBox.size.width / 2,
            startPosition.dy + startBox.size.height / 2,
          ),
          end: Offset(
            cartPosition.dx + cartBox.size.width / 2,
            cartPosition.dy + cartBox.size.height / 2,
          ),
          onEnd: () {
            entry.remove();
          },
        );
      },
    );

    overlay.insert(entry);
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

  void _onSearch(String query) {
    setState(() {
      filteredFavorit = allFavorit
          .where(
            (b) =>
                b.namaBarang.toLowerCase().contains(query.toLowerCase()) ||
                (b.seri?.toLowerCase().contains(query.toLowerCase()) ?? false),
          )
          .toList();
    });
  }

  void _toggleFav(BarangModel barang) async {
    setState(() {
      barang.isFavorit = false;
      allFavorit.removeWhere((b) => b.id == barang.id);
      filteredFavorit.removeWhere((b) => b.id == barang.id);
    });

    final res = await FavoritService.toggleFavorit(barang.id);

    if (res == null || res['success'] != true) {
      if (!mounted) return;

      setState(() {
        barang.isFavorit = true;
        _loadFavorit();
      });
    }
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

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
              _buildHeader(isDark, cardColor, textColor, subTextColor),
              const SizedBox(height: 10),
              _buildSearchBar(isDark),
              const SizedBox(height: 6),
              Expanded(
                child: FutureBuilder<List<BarangModel>>(
                  future: futureFavorit,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        allFavorit.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildEmpty(
                        "Gagal memuat favorit",
                        subTextColor,
                      );
                    }

                    if (snapshot.hasData && allFavorit.isEmpty) {
                      allFavorit = snapshot.data!;
                      filteredFavorit = snapshot.data!;

                      for (var item in filteredFavorit) {
                        item.isFavorit = true;
                      }
                    }

                    if (filteredFavorit.isEmpty) {
                      return _buildEmpty(
                        "Belum ada barang favorit",
                        subTextColor,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshFavorit,
                      color: primaryBlue,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredFavorit.length,
                        itemBuilder: (context, index) {
                          return _buildGridItem(
                            filteredFavorit[index],
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                            isDark,
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
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
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
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
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
                  "Barang Favorit",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${filteredFavorit.length} barang disimpan",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildCartIcon(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: TextField(
          onChanged: _onSearch,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: "Cari barang favorit...",
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? accentBlue : primaryBlue,
              size: 21,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String text, Color subTextColor) {
    return RefreshIndicator(
      onRefresh: _refreshFavorit,
      color: primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(
            Icons.favorite_border_rounded,
            size: 72,
            color: subTextColor.withOpacity(0.45),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return InkWell(
      key: _cartKey,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KeranjangScreen(
              keranjang: CartService.keranjang,
              semuaBarang: CartService.semuaBarang,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(100),
      child: AnimatedScale(
        scale: animasiKeranjang ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              if (totalItemDiKeranjang > 0)
                Positioned(
                  right: -3,
                  top: -3,
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BarangModel item,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDark,
  ) {
    final bool isKosong = item.stok <= 0;
    final int jumlah = CartService.getJumlah(item.id);
    final GlobalKey addButtonKey = GlobalKey();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
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
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? darkBg : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child:
                        item.fotoBarang != null && item.fotoBarang!.isNotEmpty
                            ? Image.network(
                                item.fotoBarang!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return Icon(
                                    Icons.inventory_2_rounded,
                                    color: isDark ? accentBlue : primaryBlue,
                                    size: 38,
                                  );
                                },
                              )
                            : Icon(
                                Icons.inventory_2_rounded,
                                color: isDark ? accentBlue : primaryBlue,
                                size: 38,
                              ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: InkWell(
                    onTap: () => _toggleFav(item),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaBarang,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "SN: ${item.seri ?? '-'}",
                    style: TextStyle(
                      fontSize: 10,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isKosong
                          ? Colors.red.withOpacity(0.10)
                          : Colors.green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isKosong ? "Habis" : "Stok ${item.stok}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isKosong ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (jumlah > 0) ...[
                        _qtyButton(
                          icon: Icons.remove_rounded,
                          color: Colors.red,
                          onTap: () => kurangBarang(item),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$jumlah',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _qtyButton(
                        key: addButtonKey,
                        icon: Icons.add_rounded,
                        color: isKosong || jumlah >= item.stok
                            ? Colors.grey
                            : primaryBlue,
                        onTap: isKosong || jumlah >= item.stok
                            ? null
                            : () => tambahBarang(item, addButtonKey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    Key? key,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      key: key,
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
}

class _FlyingCartAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onEnd;

  const _FlyingCartAnimation({
    required this.start,
    required this.end,
    required this.onEnd,
  });

  State<_FlyingCartAnimation> createState() => _FlyingCartAnimationState();
}

class _FlyingCartAnimationState extends State<_FlyingCartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;

  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEnd();
      }
    });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _calculatePosition(double t) {
    final x = widget.start.dx + (widget.end.dx - widget.start.dx) * t;

    final y = widget.start.dy +
        (widget.end.dy - widget.start.dy) * t -
        (80 * (1 - (2 * t - 1).abs()));

    return Offset(x, y);
  }

  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, child) {
            final t = _curve.value;
            final position = _calculatePosition(t);
            final scale = 1.0 - (t * 0.45);

            return Stack(
              children: [
                Positioned(
                  left: position.dx - 17,
                  top: position.dy - 17,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: 1 - (t * 0.15),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryBlue, secondaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}