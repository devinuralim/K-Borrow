import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/peminjaman_model.dart';
import '../services/peminjaman_service.dart';

class PengembalianBarangScreen extends StatefulWidget {
  final PeminjamanModel peminjaman;

  const PengembalianBarangScreen({super.key, required this.peminjaman});

  @override
  State<PengembalianBarangScreen> createState() => _PengembalianBarangScreenState();
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

  void _handleSubmit() async {
    if (_image == null) {
      _showSnackBar("Harap ambil foto barang sebagai bukti!");
      return;
    }

    if (_ketController.text.trim().isEmpty) {
      _showSnackBar("Keterangan kondisi barang wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await PeminjamanService.kembalikanBarang(
        id: widget.peminjaman.id,
        keterangan: _ketController.text,
        image: _image!,
      );

      if (success) {
        if (mounted) {
          _showSnackBar("Berhasil mengembalikan barang!", isError: false);
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar("Gagal mengirim data. Coba lagi.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _ketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Form Pengembalian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info Barang
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
                  const Icon(Icons.assignment_return_rounded, color: Colors.white70, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    widget.peminjaman.barang?.namaBarang ?? 'Barang Tidak Diketahui',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Jumlah: ${widget.peminjaman.jumlah} Unit",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                  // Section Foto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "BUKTI FOTO BARANG", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12, 
                          color: isDark ? Colors.white70 : Colors.blueGrey
                        )
                      ),
                      if (_image != null)
                        Text("Size: $_imageSize", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isLoading ? null : _takePicture,
                    child: Container(
                      height: 230,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03), 
                            blurRadius: 15, 
                            offset: const Offset(0, 5)
                          )
                        ],
                      ),
                      child: _image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 50, color: isDark ? Colors.white10 : Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  "Ambil Foto Kondisi Barang", 
                                  style: TextStyle(color: isDark ? Colors.white30 : Colors.grey, fontWeight: FontWeight.w500)
                                ),
                                Text(
                                  "Klik untuk membuka kamera", 
                                  style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 11)
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
                                        icon: const Icon(Icons.refresh, color: Colors.white),
                                        onPressed: _takePicture,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  // Section Keterangan
                  Text(
                    "KETERANGAN KONDISI", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 12, 
                      color: isDark ? Colors.white70 : Colors.blueGrey
                    )
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ketController,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Jelaskan kondisi barang saat dikembalikan...",
                      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDark ? Colors.blueAccent : const Color(0xFF1d3557), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Button Submit
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.green[700] : const Color(0xFF2e7d32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded),
                                SizedBox(width: 10),
                                Text("KONFIRMASI PENGEMBALIAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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