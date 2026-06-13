import '../models/barang_model.dart';

class CartService {
  static final Map<int, int> keranjang = {};
  static final Map<int, BarangModel> barangCache = {};

  static void tambahBarang(BarangModel barang) {
    barangCache[barang.id] = barang;
    keranjang[barang.id] = (keranjang[barang.id] ?? 0) + 1;
  }

  static void kurangBarang(BarangModel barang) {
    if (!keranjang.containsKey(barang.id)) return;

    if (keranjang[barang.id]! > 1) {
      keranjang[barang.id] = keranjang[barang.id]! - 1;
    } else {
      keranjang.remove(barang.id);
      barangCache.remove(barang.id);
    }
  }

  static int getJumlah(int barangId) {
    return keranjang[barangId] ?? 0;
  }

  static int get totalItem {
    return keranjang.values.fold(0, (total, jumlah) => total + jumlah);
  }

  static List<BarangModel> get semuaBarang {
    return barangCache.values.toList();
  }

  static void clear() {
    keranjang.clear();
    barangCache.clear();
  }
}