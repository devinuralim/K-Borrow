import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';

const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);
const Color backgroundGray = Color(0xFFF6F8FC);
const Color darkBg = Color(0xFF0F172A);
const Color darkCard = Color(0xFF1E293B);
const Color accentBlue = Color(0xFFa8dadc);

class PengembalianBarangScreen extends StatefulWidget {
  final PeminjamanModel? peminjaman;
  final List<int>? peminjamanIds;
  final List<PeminjamanModel>? selectedItems;
  final String kondisiPengembalian;
  const PengembalianBarangScreen({
    super.key,
    this.peminjaman,
    this.peminjamanIds,
    this.selectedItems,
    required this.kondisiPengembalian,
  });

  State<PengembalianBarangScreen> createState() {
    return _PengembalianBarangScreenState();
  }
}

class _PengembalianBarangScreenState extends State<PengembalianBarangScreen> {
  File? _image;
  String _imageSize = "0 MB";

  final _ketController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.length();

      setState(() {
        _image = file;
        _imageSize = "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
      });
    }
  }

  String get _judulKondisi {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return 'Baik';
      case 'rusak':
        return 'Rusak';
      case 'hilang':
        return 'Hilang';
      case 'tertunda':
        return 'Tertunda';
      default:
        return 'Baik';
    }
  }

  String get _judulFoto {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return "Bukti Foto Barang";
      case 'rusak':
        return "Bukti Foto Kerusakan";
      case 'hilang':
        return "Bukti / Foto Pendukung";
      case 'tertunda':
        return "Foto Barang Saat Ini";
      default:
        return "Bukti Foto Barang";
    }
  }

  String get _hintKeterangan {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return "Jelaskan kondisi barang saat dikembalikan...";
      case 'rusak':
        return "Jelaskan bagian yang rusak...";
      case 'hilang':
        return "Isi kronologi kehilangan barang...";
      case 'tertunda':
        return "Isi alasan barang belum bisa dikembalikan...";
      default:
        return "Isi keterangan...";
    }
  }

  String get _buttonText {
    switch (widget.kondisiPengembalian) {
      case 'tertunda':
        return "Kirim Pengajuan";
      default:
        return "Kirim Pengembalian";
    }
  }

  Color get _kondisiColor {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return Colors.green;
      case 'rusak':
        return Colors.orange;
      case 'hilang':
        return Colors.red;
      case 'tertunda':
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  IconData get _kondisiIcon {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return Icons.check_circle_rounded;
      case 'rusak':
        return Icons.warning_rounded;
      case 'hilang':
        return Icons.cancel_rounded;
      case 'tertunda':
        return Icons.schedule_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  void _handleSubmit() async {
    if (widget.kondisiPengembalian != 'hilang' && _image == null) {
      _showSnackBar("Harap ambil foto sebagai bukti!", isError: true);
      return;
    }

    if (_ketController.text.trim().isEmpty) {
      _showSnackBar("Keterangan wajib diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = false;

      if (widget.peminjamanIds != null && widget.peminjamanIds!.isNotEmpty) {
        success = await PeminjamanService.kembalikanBarangMassal(
          ids: widget.peminjamanIds!,
          kondisiPengembalian: widget.kondisiPengembalian,
          keterangan: _ketController.text.trim(),
          image: _image,
        );
      } else {
        success = await PeminjamanService.kembalikanBarang(
          id: widget.peminjaman!.id,
          kondisiPengembalian: widget.kondisiPengembalian,
          keterangan: _ketController.text.trim(),
          image: _image ?? File(''),
        );
      }

      if (success) {
        if (!mounted) return;

        _showSnackBar(
          "Berhasil dikirim, menunggu proses admin",
          isError: false,
        );

        Navigator.pop(context, true);
        Navigator.pop(context, true);
      } else {
        _showSnackBar("Gagal mengirim data. Coba lagi.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e", isError: true);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void dispose() {
    _ketController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    print("selectedItems: ${widget.selectedItems?.length}");
    print("peminjamanIds: ${widget.peminjamanIds}");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? darkBg : backgroundGray;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final inputFillColor = isDark ? darkBg : const Color(0xFFF8FAFC);

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
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      if (widget.kondisiPengembalian != 'hilang') ...[
                        _buildPhotoPanel(
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                      ],
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
                  "Pengembalian",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Lengkapi data pengembalian barang",
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
              Icons.assignment_return_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangPanel({
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _kondisiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              _kondisiIcon,
              color: _kondisiColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedItems != null &&
                          widget.selectedItems!.isNotEmpty
                      ? widget.selectedItems!
                          .map((e) =>
                              '${e.barang?.namaBarang ?? '-'} x${e.jumlah}')
                          .join(', ')
                      : widget.peminjaman?.barang?.namaBarang ??
                          'Barang Tidak Diketahui',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kondisiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _judulKondisi,
              style: TextStyle(
                color: _kondisiColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
            _judulFoto,
            Icons.camera_alt_rounded,
            textColor,
            subTextColor,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isLoading ? null : _takePicture,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 210,
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
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
                          "Ambil Foto",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Klik untuk membuka kamera",
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_image!, fit: BoxFit.cover),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                _imageSize,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: _isLoading ? null : _takePicture,
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 39,
                                height: 39,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                        ],
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
            controller: _ketController,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: _hintKeterangan,
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
        Icon(icon, color: primaryBlue, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (_image != null && title == _judulFoto)
          Text(
            "Sudah ada foto",
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
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
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.withOpacity(0.40),
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
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      key: const ValueKey("send"),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _buttonText,
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
