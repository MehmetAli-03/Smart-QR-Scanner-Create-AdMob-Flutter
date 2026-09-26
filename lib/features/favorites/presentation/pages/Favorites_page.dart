import 'dart:typed_data'; // Byte verisi için
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Çeviri kütüphanesi
import '../../data/favorite_dao.dart'; // Senin servis dosyan

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, String>> _favList = [];

  // Her kartın ekran görüntüsünü doğru alabilmek için benzersiz controller haritası
  final Map<String, ScreenshotController> _screenshotControllers = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final list = await FavoriteService.getFavorites();
    setState(() {
      _favList = list;
      // Listelenen her veri için bir adet ScreenshotController tanımlıyoruz
      for (var item in _favList) {
        final dataKey = item['data'] ?? '';
        if (dataKey.isNotEmpty && !_screenshotControllers.containsKey(dataKey)) {
          _screenshotControllers[dataKey] = ScreenshotController();
        }
      }
    });
  }

  Future<void> _saveFavImage(ScreenshotController controller) async {
    final t = AppLocalizations.of(context)!;
    try {
      final Uint8List? bytes = await controller.capture();
      if (bytes != null) {
        await Gal.putImageBytes(bytes, album: t.qrFavoritesAlbum);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.favoriteSavedToGallery),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      print("Kaydetme hatası: $e");
    }
  }

  Future<void> _launchURL(String text) async {
    final t = AppLocalizations.of(context)!;
    String urlString = text.trim();

    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      if (urlString.contains('.')) {
        urlString = 'https://$urlString';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.notALink, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.linkOpenError, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Yanlışlıkla silmeleri önlemek için onay penceresi (Harika bir UX detayı)
  void _showDeleteConfirmDialog(String data) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(t.delete ?? "Sil", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Bu QR kodu favorilerinizden silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FavoriteService.removeFavorite(data);
                _loadFavorites();
              },
              child: const Text("Sil", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(t.myFavorites, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _favList.isEmpty
          ? Center(child: Text(t.noFavoritesYet, style: const TextStyle(fontSize: 16, color: Colors.grey)))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        itemCount: _favList.length,
        itemBuilder: (context, index) {
          final item = _favList[index];
          final title = item['title'] ?? '';
          final data = item['data'] ?? '';

          // Kayıtlı controller'ı çekiyoruz, yoksa anlık bir tane oluşturup bağlıyoruz
          final controller = _screenshotControllers[data] ?? ScreenshotController();

          return _buildFavoriteGridCard(title, data, controller);
        },
      ),
    );
  }

  Widget _buildFavoriteGridCard(String title, String data, ScreenshotController cardController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Başlık Alanı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // QR KOD ALANI
          Expanded(
            child: Screenshot(
              controller: cardController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 100,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // ALT BİLGİ VE BUTONLAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                Text(
                  data,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // LİNKE GİT BUTONU
                    GestureDetector(
                      onTap: () => _launchURL(data),
                      child: const Icon(Icons.open_in_browser_rounded, color: Colors.green, size: 24),
                    ),
                    // İNDİR BUTONU
                    GestureDetector(
                      onTap: () => _saveFavImage(cardController),
                      child: const Icon(Icons.file_download_outlined, color: Colors.blueAccent, size: 24),
                    ),
                    // SİL BUTONU
                    GestureDetector(
                      onTap: () => _showDeleteConfirmDialog(data),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}