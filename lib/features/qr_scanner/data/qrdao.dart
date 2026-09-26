import 'dart:io'; // Dosya işlemleri için
import 'dart:typed_data'; // Byte işlemleri için
import 'package:path_provider/path_provider.dart'; // Klasör bulmak için
import 'package:share_plus/share_plus.dart'; // Paylaşmak için
import 'package:qr_scanner_create/features/qr_scanner/data/model/qr_model.dart';
import '../../../core/database/helpDataBase.dart';

class QrDao {

  // --- 1. VERİ EKLEME (SQLITE) ---
  Future<void> qrAdd(String name, String data, String date) async {
    var db = await Helpdatabase.veritabaniErisim();
    var yeniKayit = <String, dynamic>{
      "name": name,
      "data": data,
      "date": date,
    };
    await db.insert("pastqr", yeniKayit);
  }

  // --- 2. LİSTELEME (SQLITE) ---
  Future<List<QR>> qrList() async {
    var db = await Helpdatabase.veritabaniErisim();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM pastqr ORDER BY date DESC");

    return List.generate(maps.length, (i) {
      var satir = maps[i];
      return QR(
        satir["Id"],
        satir["name"],
        satir["data"],
        satir["date"],
      );
    });
  }

  // --- 3. SİLME (SQLITE) ---
  Future<void> qrDelete(int qrId) async {
    var db = await Helpdatabase.veritabaniErisim();
    await db.delete("pastqr", where: "Id = ?", whereArgs: [qrId]);
  }

  // --- 4. PAYLAŞMA SERVİSİ (YENİ EKLENDİ) 🚀 ---
  // Bu metodun veritabanıyla işi yok, o yüzden 'static' yapabiliriz.
  // Böylece nesne üretmeden QrDao.shareQrImage(...) diye çağırabilirsin.
  static Future<void> shareQrImage(Uint8List bytes) async {
    try {
      // 1. Telefonun geçici dizinini bul
      final directory = await getTemporaryDirectory();

      // 2. Oraya geçici bir dosya oluştur (Her seferinde üzerine yazsın diye sabit isim)
      final imagePath = await File('${directory.path}/shared_qr.png').create();

      // 3. Byteları dosyaya yaz
      await imagePath.writeAsBytes(bytes);

      // 4. Paylaşım penceresini aç
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'QR Kodunu seninle paylaşıyorum! 🚀',
      );
    } catch (e) {
      // Hata olursa konsola yazsın, UI tarafında try-catch ile yakalarız
      throw Exception("Paylaşım hatası: $e");
    }
  }
}