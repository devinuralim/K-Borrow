import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';

const Color primaryNavy = Color(0xFF1d3557);

class UploadTindakLanjutScreen extends StatefulWidget {
  final PeminjamanModel peminjaman;
  final String tipe;

  const UploadTindakLanjutScreen({
    super.key,
    required this.peminjaman,
    required this.tipe,
  });

  State<UploadTindakLanjutScreen> createState() =>
      _UploadTindakLanjutScreenState();
}

class _UploadTindakLanjutScreenState extends State<UploadTindakLanjutScreen> {
  final TextEditingController _keteranganController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isLoading = false;

  String get _title {
    if (widget.tipe == 'perbaikan') return 'Upload Bukti Perbaikan';
    if (widget.tipe == 'ganti_rugi') return 'Upload Bukti Pembayaran';
    if (widget.tipe == 'ganti_barang') return 'Upload Barang Pengganti';
    return 'Upload Bukti';
  }

  String get _labelFoto {
    if (widget.tipe == 'perbaikan') return 'Foto Barang Setelah Diperbaiki';
    if (widget.tipe == 'ganti_rugi') return 'Foto Bukti Bayar';
    if (widget.tipe == 'ganti_barang') return 'Foto Barang Pengganti';
    return 'Foto Bukti';
  }

  String get _hintKeterangan {
    if (widget.tipe == 'perbaikan') {
      return 'Contoh: Barang sudah diperbaiki, layar sudah normal kembali.';
    }

    if (widget.tipe == 'ganti_rugi') {
      return 'Contoh: Pembayaran ganti rugi sudah ditransfer.';
    }

    if (widget.tipe == 'ganti_barang') {
      return 'Contoh: Barang pengganti dengan tipe dan kondisi yang sama.';
    }

    return 'Isi keterangan';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (_image == null) {
      _showSnack('Foto bukti wajib diisi');
      return;
    }

    if (_keteranganController.text.trim().isEmpty &&
        widget.tipe != 'ganti_rugi') {
      _showSnack('Keterangan wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    bool success = false;

    if (widget.tipe == 'perbaikan') {
      success = await PeminjamanService.uploadPerbaikan(
        id: widget.peminjaman.id,
        buktiPerbaikan: _image!,
        keterangan: _keteranganController.text.trim(),
      );
    } else if (widget.tipe == 'ganti_rugi') {
      success = await PeminjamanService.uploadGantiRugi(
        id: widget.peminjaman.id,
        buktiTransfer: _image!,
        keterangan: _keteranganController.text.trim(),
      );
    } else if (widget.tipe == 'ganti_barang') {
      success = await PeminjamanService.uploadGantiBarang(
        id: widget.peminjaman.id,
        buktiBarang: _image!,
        keterangan: _keteranganController.text.trim(),
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      _showSnack('Bukti berhasil dikirim');
      Navigator.pop(context, true);
    } else {
      _showSnack('Gagal mengirim bukti');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildImageBox({
    required String title,
    required File? file,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optional ? '$title (Opsional)' : title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isLoading ? null : onTap,
          child: Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ambil Foto',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klik untuk membuka kamera',
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.grey,
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
                        Image.file(file, fit: BoxFit.cover),
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
                              onPressed: _isLoading ? null : onTap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: primaryNavy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.peminjaman.barang?.namaBarang ?? 'Barang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryNavy,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.peminjaman.jumlah} unit',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _buildImageBox(title: _labelFoto, file: _image, onTap: _pickImage),

            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'KETERANGAN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _keteranganController,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: _hintKeterangan,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
                  borderSide: const BorderSide(color: primaryNavy, width: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 21,
                        width: 21,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'KIRIM BUKTI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
