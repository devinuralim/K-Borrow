import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/barang_model.dart';
import '../services/peminjaman_service.dart';
import '../services/cart_service.dart';
import 'home_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class PengajuanScreen extends StatefulWidget {
  final Map<int, int> keranjang;
  final List<BarangModel> semuaBarang;

  const PengajuanScreen({
    super.key,
    required this.keranjang,
    required this.semuaBarang,
  });

  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  final TextEditingController keteranganController = TextEditingController();

  File? _image;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  void dispose() {
    keteranganController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _kirimPengajuan(List<BarangModel> items) async {
    if (_isLoading) return;

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan upload foto terlebih dahulu"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final itemsPinjam = items.map((barang) {
      return {
        "barang_id": barang.id,
        "jumlah": widget.keranjang[barang.id],
      };
    }).toList();

    final berhasil = await PeminjamanService.pinjamBanyakBarang(
      items: itemsPinjam,
      image: _image!,
      keterangan: keteranganController.text,
    );

    if (!mounted) return;

    if (berhasil) {
      CartService.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pengajuan berhasil dikirim"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengirim pengajuan"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final inputFillColor = isDark ? darkBg : const Color(0xFFF8FAFC);

    final items = widget.semuaBarang
        .where((barang) => widget.keranjang.containsKey(barang.id))
        .toList();

    int totalJumlah = 0;
    for (final item in items) {
      totalJumlah += widget.keranjang[item.id] ?? 0;
    }

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
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
                itemCount: items.length,
                totalJumlah: totalJumlah,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: Column(
                    children: [
                      _buildBarangPanel(
                        items: items,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildPhotoPanel(
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildKeteranganPanel(
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        inputFillColor: inputFillColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(
        isDark: isDark,
        items: items,
        totalJumlah: totalJumlah,
      ),
    );
  }

  Widget _buildHeader({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required int itemCount,
    required int totalJumlah,
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
                  "Pengajuan",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "$itemCount barang • $totalJumlah item",
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
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangPanel({
    required List<BarangModel> items,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            "Barang Dipinjam",
            Icons.inventory_2_rounded,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          ...items.map((barang) {
            final jumlah = widget.keranjang[barang.id] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark ? darkBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: barang.fotoBarang != null &&
                              barang.fotoBarang!.isNotEmpty
                          ? Image.network(
                              barang.fotoBarang!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.inventory_2_rounded,
                                  color: isDark ? accentBlue : primaryBlue,
                                );
                              },
                            )
                          : Icon(
                              Icons.inventory_2_rounded,
                              color: isDark ? accentBlue : primaryBlue,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      barang.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      "x$jumlah",
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoPanel({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            "Foto Barang",
            Icons.camera_alt_rounded,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _takePicture,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? darkBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _image == null
                      ? borderColor
                      : Colors.green.withOpacity(0.45),
                ),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Ambil foto barang",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Foto wajib sebelum pengajuan dikirim",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeteranganPanel({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color inputFillColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            "Keterangan",
            Icons.notes_rounded,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: keteranganController,
            maxLines: 4,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: "Contoh: Digunakan untuk instalasi jaringan",
              hintStyle: TextStyle(
                color: subTextColor,
                fontSize: 12,
              ),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDark ? accentBlue : primaryBlue,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryBlue,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
            onPressed: _isLoading ? null : () => _kirimPengajuan(items),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryBlue.withOpacity(0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey("loading"),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey("submit"),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Kirim Pengajuan ($totalJumlah)",
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
      ),
    );
  }
}