import 'dart:io';
import 'package:flutter/material.dart';
import 'riwayat_peminjaman_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../models/barang_model.dart';
import '../services/peminjaman_service.dart';
import '../services/cart_service.dart';
import 'home_screen.dart';

const Color primaryBlue = Color(0xFF1d3557);

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

  Widget build(BuildContext context) {
    final items = widget.semuaBarang
        .where((barang) => widget.keranjang.containsKey(barang.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text("Pengajuan Peminjaman"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Barang Yang Dipinjam",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            ...items.map((barang) {
              return Card(
                child: ListTile(
                  leading: barang.fotoBarang != null
                      ? Image.network(
                          barang.fotoBarang!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.inventory),

                  title: Text(barang.namaBarang),

                  subtitle: Text("Jumlah: ${widget.keranjang[barang.id]}"),
                ),
              );
            }),

            const SizedBox(height: 25),

            const Text(
              "Foto Barang Saat Dipinjam",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 50),
                          SizedBox(height: 10),
                          Text("Klik untuk mengambil foto"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Keterangan Peminjaman",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: keteranganController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Contoh: Digunakan untuk instalasi jaringan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_isLoading) return;

                        setState(() {
                          _isLoading = true;
                        });

                        if (_image == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Silakan upload foto terlebih dahulu",
                              ),
                            ),
                          );

                          setState(() {
                            _isLoading = false;
                          });

                          return;
                        }

                        final itemsPinjam = items.map((barang) {
                          return {
                            "barang_id": barang.id,
                            "jumlah": widget.keranjang[barang.id],
                          };
                        }).toList();

                        final berhasil =
                            await PeminjamanService.pinjamBanyakBarang(
                              items: itemsPinjam,
                              image: _image!,
                              keterangan: keteranganController.text,
                            );

                        if (berhasil) {
                          CartService.clear();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Pengajuan berhasil dikirim"),
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
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Kirim Pengajuan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
