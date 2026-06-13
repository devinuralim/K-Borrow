import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';

class PengembalianBarangScreen extends StatefulWidget {
  final PeminjamanModel peminjaman;
  final String kondisiPengembalian;

  const PengembalianBarangScreen({
    super.key,
    required this.peminjaman,
    required this.kondisiPengembalian,
  });

  State<PengembalianBarangScreen> createState() =>
      _PengembalianBarangScreenState();
}

class _PengembalianBarangScreenState extends State<PengembalianBarangScreen> {
  File? _image;
  String _imageSize = "0 MB";

  final _ketController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;

  final Color primaryNavy = const Color(0xFF1d3557);

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
        return "BUKTI FOTO BARANG";
      case 'rusak':
        return "BUKTI FOTO KERUSAKAN";
      case 'hilang':
        return "BUKTI / FOTO PENDUKUNG";
      case 'tertunda':
        return "FOTO BARANG SAAT INI";
      default:
        return "BUKTI FOTO BARANG";
    }
  }

  String get _hintKeterangan {
    switch (widget.kondisiPengembalian) {
      case 'baik':
        return "Jelaskan kondisi barang saat dikembalikan...";
      case 'rusak':
        return "Jelaskan bagian yang rusak. Contoh: layar proyektor tergores...";
      case 'hilang':
        return "Isi kronologi kehilangan barang...";
      case 'tertunda':
        return "Isi alasan kenapa barang belum bisa dikembalikan...";
      default:
        return "Isi keterangan...";
    }
  }

  String get _buttonText {
    switch (widget.kondisiPengembalian) {
      case 'tertunda':
        return "KIRIM PENGAJUAN";
      default:
        return "KIRIM PENGEMBALIAN";
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
      final success = await PeminjamanService.kembalikanBarang(
        id: widget.peminjaman.id,
        kondisiPengembalian: widget.kondisiPengembalian,
        keterangan: _ketController.text.trim(),
        image: _image ?? File(''),
      );

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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void dispose() {
    _ketController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Form Pengembalian",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: BoxDecoration(
                color: primaryNavy,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_return_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.peminjaman.barang?.namaBarang ??
                        'Barang Tidak Diketahui',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Jumlah: ${widget.peminjaman.jumlah} Unit",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Kondisi: $_judulKondisi",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.kondisiPengembalian != 'hilang') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _judulFoto,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.blueGrey,
                          ),
                        ),
                        if (_image != null)
                          Text(
                            "Size: $_imageSize",
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _isLoading ? null : _takePicture,
                      child: Container(
                        height: 230,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade300,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.03,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 50,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Ambil Foto",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "Klik untuk membuka kamera",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_image!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : _takePicture,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],

                  Text(
                    "KETERANGAN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _ketController,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _hintKeterangan,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.blueAccent
                              : const Color(0xFF1d3557),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.green[700]
                            : const Color(0xFF2e7d32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded),
                                const SizedBox(width: 10),
                                Text(
                                  _buttonText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
