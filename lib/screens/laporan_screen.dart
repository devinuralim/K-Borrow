import 'package:flutter/material.dart';
import '../models/barang_model.dart';
import '../services/barang_service.dart';
import '../services/laporan_service.dart';
import 'riwayat_laporan_screen.dart';

const Color primaryNavy = Color(0xFF1d3557);
const Color dangerRed = Color(0xFFb91c1c);
const Color infoBlue = Color(0xFF3b82f6);

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController();

  int? _selectedBarangId;
  String _jenisLaporan = "Rusak";
  bool _isLoading = false;

  @override
  void dispose() {
    _deskripsiController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  void _submitLaporan() async {
    if (_selectedBarangId == null) {
      _showSnackBar("⚠️ Silakan pilih barang dulu", Colors.orange);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await LaporanService.kirimLaporan(
        barangId: _selectedBarangId!,
        jenis: _jenisLaporan.toLowerCase(),
        jumlah: int.parse(_jumlahController.text),
        deskripsi: _deskripsiController.text,
      );

      if (success) {
        if (!mounted) return;
        _showSnackBar("✅ Laporan berhasil dikirim!", Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RiwayatLaporanScreen()),
        );
      } else {
        _showSnackBar("❌ Gagal mengirim laporan", dangerRed);
      }
    } catch (e) {
      _showSnackBar("❌ Terjadi kesalahan: $e", dangerRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Lapor Masalah Barang",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              color: primaryNavy,
              child: const Text(
                "Laporkan jika ada barang K2NET yang rusak, hilang, atau tertinggal agar segera diproses.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Card(
                elevation: isDark ? 0 : 2,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _LabelText(label: "PILIH BARANG"),
                        const SizedBox(height: 10),
                        FutureBuilder<List<BarangModel>>(
                          future: BarangService.getBarang(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator(
                                  color: primaryNavy, backgroundColor: Colors.black12);
                            }
                            final items = snapshot.data ?? [];
                            return DropdownButtonFormField<int>(
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: _inputStyle(Icons.inventory_2_outlined, isDark),
                              initialValue: _selectedBarangId,
                              hint: const Text("Pilih Barang"),
                              items: items
                                  .map((b) => DropdownMenuItem<int>(
                                        value: b.id,
                                        child: Text(b.namaBarang,
                                            style: const TextStyle(fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedBarangId = val),
                              validator: (v) => v == null ? "Wajib pilih barang" : null,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const _LabelText(label: "JENIS MASALAH"),
                        const SizedBox(height: 5),
                        
                        // Perbaikan Radio agar lebih rapat dan tidak overflow
                        Row(
                          children: [
                            Expanded(child: _buildRadioOption("Rusak", dangerRed, isDark)),
                            Expanded(child: _buildRadioOption("Hilang", Colors.grey, isDark)),
                            Expanded(child: _buildRadioOption("Tertinggal", infoBlue, isDark)),
                          ],
                        ),

                        const SizedBox(height: 15),
                        const _LabelText(label: "JUMLAH UNIT"),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _jumlahController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: _inputStyle(Icons.numbers_rounded, isDark, hint: "Masukkan jumlah unit"),
                          validator: (v) => v!.isEmpty ? "Isi jumlah unit" : null,
                        ),
                        const SizedBox(height: 20),
                        const _LabelText(label: "KRONOLOGI / KETERANGAN"),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _deskripsiController,
                          maxLines: 4,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: _inputStyle(null, isDark, hint: "Jelaskan detail kejadian..."),
                          validator: (v) => v!.isEmpty ? "Isi keterangan laporan" : null,
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitLaporan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("KIRIM LAPORAN", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildRadioOption(String label, Color color, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: isDark ? Colors.white30 : Colors.grey,
      ),
      child: RadioListTile(
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        title: Transform.translate(
          offset: const Offset(-8, 0), // Menggeser teks agar lebih dekat ke tombol radio
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white70 : Colors.black87
            ),
          ),
        ),
        value: label,
        activeColor: color,
        groupValue: _jenisLaporan,
        onChanged: (v) => setState(() => _jenisLaporan = v.toString()),
      ),
    );
  }

  InputDecoration _inputStyle(IconData? icon, bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primaryNavy, width: 1.5)),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  const _LabelText({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(label,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isDark ? Colors.blueGrey[200] : primaryNavy,
            letterSpacing: 1.0));
  }
}