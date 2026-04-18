import 'barang_model.dart';

class PeminjamanModel {
  final int id;
  final int barangId;
  final BarangModel? barang; // Ini sudah benar
  final int jumlah;
  final String keterangan;
  final String status;
  final DateTime tanggalPinjam;
  final DateTime? tanggalKembali;

  PeminjamanModel({
    required this.id,
    required this.barangId,
    required this.jumlah,
    required this.keterangan,
    required this.status,
    required this.tanggalPinjam,
    this.tanggalKembali,
    this.barang,
  });

  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      id: json['id'],
      barangId: json['barang_id'],
      jumlah: json['jumlah'],
      keterangan: json['keterangan'] ?? "",
      status: json['status'] ?? "dipinjam",
      tanggalPinjam: DateTime.parse(json['tanggal_pinjam']),
      tanggalKembali: json['tanggal_kembali'] != null
          ? DateTime.parse(json['tanggal_kembali'])
          : null,
      // TAMBAHKAN BARIS INI: parsing data barang dari nested json
      barang: json['barang'] != null ? BarangModel.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "barang_id": barangId,
        "jumlah": jumlah,
        "keterangan": keterangan,
        "status": status,
        "tanggal_pinjam": tanggalPinjam.toIso8601String(),
        "tanggal_kembali": tanggalKembali?.toIso8601String(),
      };
}