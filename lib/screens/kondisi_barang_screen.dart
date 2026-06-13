import 'package:flutter/material.dart';
import '../models/peminjaman_model.dart';
import 'pengembalian_barang_screen.dart';

class KondisiBarangScreen extends StatefulWidget {
  final PeminjamanModel peminjaman;
  final String? forceKondisi;

  const KondisiBarangScreen({
    super.key,
    required this.peminjaman,
    this.forceKondisi,
  });

  State<KondisiBarangScreen> createState() => _KondisiBarangScreenState();
}

class _KondisiBarangScreenState extends State<KondisiBarangScreen> {
  late String _selectedKondisi;

  final Color primaryNavy = const Color(0xFF1d3557);

  final List<Map<String, dynamic>> kondisiList = [
    {
      'value': 'baik',
      'title': 'Baik',
      'subtitle': 'Barang dikembalikan dalam kondisi baik',
      'icon': Icons.check_circle_rounded,
    },
    {
      'value': 'rusak',
      'title': 'Rusak',
      'subtitle': 'Barang mengalami kerusakan',
      'icon': Icons.warning_rounded,
    },
    {
      'value': 'hilang',
      'title': 'Hilang',
      'subtitle': 'Barang tidak dapat dikembalikan karena hilang',
      'icon': Icons.cancel_rounded,
    },
    {
      'value': 'tertunda',
      'title': 'Tertunda',
      'subtitle': 'Barang belum bisa dikembalikan sekarang',
      'icon': Icons.schedule_rounded,
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PengembalianBarangScreen(
          peminjaman: widget.peminjaman,
          kondisiPengembalian: _selectedKondisi,
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.forceKondisi == 'baik') {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1d3557)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Kondisi Barang",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                  Icons.inventory_2_rounded,
                  color: Colors.white70,
                  size: 45,
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
                const SizedBox(height: 6),
                Text(
                  "Jumlah: ${widget.peminjaman.jumlah} Unit",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: kondisiList.length,
              itemBuilder: (context, index) {
                final item = kondisiList[index];
                final isSelected = _selectedKondisi == item['value'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedKondisi = item['value'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryNavy : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'],
                          size: 32,
                          color: isSelected ? primaryNavy : Colors.grey,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: item['value'],
                          groupValue: _selectedKondisi,
                          activeColor: primaryNavy,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedKondisi = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _lanjut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "LANJUT",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
