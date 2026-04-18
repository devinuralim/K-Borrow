import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/barang_service.dart';
import '../services/peminjaman_service.dart';
import 'riwayat_peminjaman_screen.dart';

// Warna branding tetap konsisten
const Color primaryBlue = Color(0xFF1d3557);
const Color secondaryBlue = Color(0xFF457b9d);

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({super.key});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();

  BarangModel? _tempBarang;
  List<Map<String, dynamic>> daftarPinjaman = [];

  late Future<List<BarangModel>> futureBarang;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    futureBarang = BarangService.getBarang();
  }
void _showBarangSearch(List<BarangModel> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        List<BarangModel> filteredItems = items;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Cari & Pilih Barang", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Ketik nama barang...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        filteredItems = items
                            .where((b) => b.namaBarang.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final b = filteredItems[index];
                        return ListTile(
                          title: Text(b.namaBarang),
                          subtitle: Text("Stok: ${b.stok}"),
                          onTap: () {
                            setState(() => _tempBarang = b);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _tambahBarang() {
    if (_tempBarang == null || _jumlahController.text.isEmpty) {
      _showSnackBar("Pilih barang & isi jumlah", Colors.orange);
      return;
    }

    int jumlah = int.tryParse(_jumlahController.text) ?? 0;

    if (jumlah <= 0) {
      _showSnackBar("Jumlah harus lebih dari 0", Colors.orange);
      return;
    }

    if (jumlah > _tempBarang!.stok) {
      _showSnackBar("Stok tidak mencukupi (Tersedia: ${_tempBarang!.stok})", Colors.red);
      return;
    }

    setState(() {
      int index = daftarPinjaman.indexWhere((item) => item['barang_id'] == _tempBarang!.id);
      if (index != -1) {
        daftarPinjaman[index]['jumlah'] += jumlah;
      } else {
        daftarPinjaman.add({
          "barang_id": _tempBarang!.id,
          "nama": _tempBarang!.namaBarang,
          "jumlah": jumlah,
        });
      }
      _tempBarang = null;
      _jumlahController.clear();
    });
  }

  void _submitPinjam() async {
    if (daftarPinjaman.isEmpty) {
      if (_tempBarang != null && _jumlahController.text.isNotEmpty) {
        int jumlah = int.tryParse(_jumlahController.text) ?? 0;
        if (jumlah > 0 && jumlah <= _tempBarang!.stok) {
          daftarPinjaman.add({
            "barang_id": _tempBarang!.id,
            "nama": _tempBarang!.namaBarang,
            "jumlah": jumlah,
          });
        }
      }
    }

    if (daftarPinjaman.isEmpty) {
      _showSnackBar("Tambahkan minimal 1 barang ke daftar", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final bool success = await PeminjamanService.pinjamBanyakBarang(items: daftarPinjaman);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _showSnackBar("✅ Berhasil mengajukan peminjaman", Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatPeminjamanScreen()),
      );
    } else {
      _showSnackBar("❌ Gagal mengirim permintaan. Cek koneksi/stok.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Form Peminjaman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER INFO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: const Text(
                "Pilih barang yang ingin dipinjam dari inventaris PT K2NET.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DROPDOWN BARANG
// GANTI BAGIAN INI DI DALAM UI:
FutureBuilder<List<BarangModel>>(
  future: futureBarang,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LinearProgressIndicator(color: primaryBlue);
    }
    
    // UI Pengganti Dropdown
    return InkWell(
      onTap: () => _showBarangSearch(snapshot.data ?? []),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(15),
          border: _tempBarang != null 
              ? Border.all(color: secondaryBlue, width: 1.5) 
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2, color: isDark ? Colors.blue[200] : primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tempBarang == null 
                    ? "Pilih Barang (Klik untuk mencari)" 
                    : "${_tempBarang!.namaBarang} (Stok: ${_tempBarang!.stok})",
                style: TextStyle(
                  color: _tempBarang == null 
                      ? (isDark ? Colors.grey[400] : Colors.grey[600]) 
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  },
),
                      const SizedBox(height: 16),

                      // INPUT JUMLAH
                      TextFormField(
                        controller: _jumlahController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _inputStyle("Jumlah Barang", Icons.shopping_basket, isDark),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 20),

                      // TOMBOL TAMBAH KE LIST
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _tambahBarang,
                          icon: const Icon(Icons.add_shopping_cart, size: 20),
                          label: const Text("Tambah Peminjaman", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      if (daftarPinjaman.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),
                        Text("Item dalam keranjang:", 
                             style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : primaryBlue)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: daftarPinjaman.length,
                          itemBuilder: (context, index) {
                            final item = daftarPinjaman[index];
                            return Card(
                              elevation: 0,
                              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(item['nama'], style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                                subtitle: Text("Jumlah: ${item['jumlah']} unit", style: const TextStyle(color: Colors.grey)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                  onPressed: () => setState(() => daftarPinjaman.removeAt(index)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 25),

                      // TOMBOL KIRIM KE SERVER
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPinjam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "KIRIM PERMINTAAN PINJAM",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : primaryBlue),
      prefixIcon: Icon(icon, color: isDark ? Colors.blue[200] : primaryBlue),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F4F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: secondaryBlue, width: 1.5),
      ),
    );
  }
}