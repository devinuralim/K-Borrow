import 'barang_model.dart';

class PeminjamanModel {
  final int id;
  final int barangId;
  final BarangModel? barang;
  final int jumlah;

  final String keterangan;
  final String status;

  final String? keteranganTindakLanjut;

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
    this.keteranganTindakLanjut,
  });

  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      barangId: int.tryParse(json['barang_id'].toString()) ?? 0,
      jumlah: int.tryParse(json['jumlah'].toString()) ?? 0,

      keterangan: json['keterangan']?.toString() ?? "",

      status: json['status']?.toString() ?? "dipinjam",

      keteranganTindakLanjut:
          json['keterangan_tindak_lanjut']?.toString(),

      tanggalPinjam: DateTime.parse(
        json['tanggal_pinjam'],
      ),

      tanggalKembali: json['tanggal_kembali'] != null
          ? DateTime.parse(json['tanggal_kembali'])
          : null,

      barang: json['barang'] != null
          ? BarangModel.fromJson(json['barang'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "barang_id": barangId,
        "jumlah": jumlah,
        "keterangan": keterangan,
        "status": status,
        "keterangan_tindak_lanjut": keteranganTindakLanjut,
        "tanggal_pinjam": tanggalPinjam.toIso8601String(),
        "tanggal_kembali": tanggalKembali?.toIso8601String(),
      };
}