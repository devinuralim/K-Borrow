class BarangModel {
  final int id;
  final String namaBarang;
  final String jenisBarang;
  final int stok;
  final String? seri;
  final String? keterangan;
  bool isFavorit;

  BarangModel({
    required this.id,
    required this.namaBarang,
    required this.jenisBarang,
    required this.stok,
    this.seri,
    this.keterangan,
    this.isFavorit = false,
  });

factory BarangModel.fromJson(Map<String, dynamic> json) {
  return BarangModel(
    id: json['id'] ?? 0,
    namaBarang: json['nama_barang'] ?? '',
    jenisBarang: json['jenis_barang'] ?? '',
    stok: int.tryParse(json['stok'].toString()) ?? 0,
    seri: json['seri'],
    // Logika agar bintang menyala jika is_favorit bernilai 1 atau true
    isFavorit: json['is_favorit'] == 1 || json['is_favorit'] == true,
  );
}
}