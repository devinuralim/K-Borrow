import 'package:flutter/material.dart';
import '../models/peminjaman_model.dart';
import 'pengembalian_barang_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class KondisiBarangScreen extends StatefulWidget {
  final PeminjamanModel? peminjaman;
  final List<int>? peminjamanIds;
  final List<PeminjamanModel>? selectedItems;
  final String? forceKondisi;

const KondisiBarangScreen({
  super.key,
  this.peminjaman,
  this.peminjamanIds,
  this.selectedItems,
  this.forceKondisi,
});

  State<KondisiBarangScreen> createState() => _KondisiBarangScreenState();
}

class _KondisiBarangScreenState extends State<KondisiBarangScreen> {
  late String _selectedKondisi;

  final List<Map<String, dynamic>> kondisiList = [
    {
      'value': 'baik',
      'title': 'Baik',
      'subtitle': 'Barang dikembalikan dalam kondisi baik',
      'icon': Icons.check_circle_rounded,
      'color': Colors.green,
    },
    {
      'value': 'rusak',
      'title': 'Rusak',
      'subtitle': 'Barang mengalami kerusakan',
      'icon': Icons.warning_rounded,
      'color': Colors.orange,
    },
    {
      'value': 'hilang',
      'title': 'Hilang',
      'subtitle': 'Barang tidak dapat dikembalikan',
      'icon': Icons.cancel_rounded,
      'color': Colors.red,
    },
    {
      'value': 'tertunda',
      'title': 'Tertunda',
      'subtitle': 'Barang belum bisa dikembalikan sekarang',
      'icon': Icons.schedule_rounded,
      'color': Colors.indigo,
    },
  ];

  void initState() {
    super.initState();

    _selectedKondisi = widget.forceKondisi ?? 'baik';

    if (widget.forceKondisi == 'baik') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lanjut();
      });
    }
  }

  void _lanjut() {
    if (widget.peminjamanIds != null && widget.peminjamanIds!.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PengembalianBarangScreen(
  peminjamanIds: widget.peminjamanIds,
  selectedItems: widget.selectedItems,
  kondisiPengembalian: _selectedKondisi,
)
        ),
      );

      return;
    }

    if (widget.peminjaman == null) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PengembalianBarangScreen(
          peminjaman: widget.peminjaman!,
          kondisiPengembalian: _selectedKondisi,
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    if (widget.forceKondisi == 'baik') {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? accentBlue : primaryBlue,
          ),
        ),
      );
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
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 8),
              _buildBarangSummary(
                isDark: isDark,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  itemCount: kondisiList.length,
                  itemBuilder: (context, index) {
                    final item = kondisiList[index];
                    final isSelected = _selectedKondisi == item['value'];

                    return _buildKondisiItem(
                      item: item,
                      isSelected: isSelected,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(isDark),
    );
  }

  Widget _buildHeader({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
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
                  "Kondisi Barang",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Pilih kondisi barang saat dikembalikan",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
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
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangSummary({
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [darkCard, const Color(0xFF111827)]
              : [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(isDark ? 0.12 : 0.20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_return_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peminjaman?.barang?.namaBarang ??
                      'Barang Tidak Diketahui',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Jumlah: ${widget.peminjaman?.jumlah ?? 0} Unit",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKondisiItem({
    required Map<String, dynamic> item,
    required bool isSelected,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final Color color = item['color'];

    return InkWell(
      onTap: () {
        setState(() {
          _selectedKondisi = item['value'];
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 1.6 : 1,
          ),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                item['icon'],
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : subTextColor.withOpacity(0.45),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
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
            onPressed: _lanjut,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  "Lanjutkan",
                  style: TextStyle(
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
}
