class LaporanModel {
  final int id;
  final int barangId;
  final String jenisLaporan; // Rusak, Hilang, atau Tertinggal
  final String? keterangan;
  final int jumlah;
  final String status;
  final String namaBarang;
  final String? tanggal;

  LaporanModel({
    required this.id,
    required this.barangId,
    required this.jenisLaporan,
    this.keterangan,
    required this.jumlah,
    required this.status,
    required this.namaBarang,
    this.tanggal,
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      barangId: json['barang_id'] is String 
          ? int.parse(json['barang_id']) 
          : (json['barang_id'] ?? 0),
      jenisLaporan: json['jenis_laporan'] ?? '',
      keterangan: json['keterangan'], 
      jumlah: json['jumlah'] is String 
          ? int.parse(json['jumlah']) 
          : (json['jumlah'] ?? 0),
      status: json['status'] ?? 'menunggu',
      // Pastikan nama key 'barang' dan 'nama_barang' sesuai dengan JSON API Laravel
      namaBarang: json['barang'] != null 
          ? (json['barang']['nama_barang'] ?? 'Tanpa Nama')
          : 'Barang Terhapus',
      tanggal: json['created_at'],
    );
  }
}