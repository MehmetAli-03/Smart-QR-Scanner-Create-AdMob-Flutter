import 'dart:typed_data'; // Byte verisi için
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qr_scanner_create/features/qr_scanner/data/qrdao.dart';
import 'package:qr_scanner_create/features/history/presentation/qr_code_past.dart';
import '../../../favorites/data/favorite_dao.dart';
import '../../../../core/services/ad_service.dart';
import '../../../favorites/presentation/pages/Favorites_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();

  final QrDao _qrDao = QrDao();

  String? _qrData;
  int _selectedIndex = 1;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bannerAd = BannerAd(
      adUnitId: "ca-app-pub-3564360157775786/5218212519", // TEST BANNER ANDROID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Banner error: $error");
        },
      ),
    );

    _bannerAd!.load();

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _processQrCreation(String data) async {
    try {
      String date = DateTime.now().toIso8601String();
      await _qrDao.qrAdd("QR Code", data, date);
      AdService.instance.registerAction();
    } catch (e) {
      print("Veritabanı hatası: $e");
    }
  }

  Future<void> saveImageToGallery() async {
    final t = AppLocalizations.of(context)!;
    try {
      final Uint8List? bytes = await screenshotController.capture();
      if (bytes != null) {
        // Geniş izin istemeden çalışan modern galeriye kaydetme yöntemi
        await Gal.putImageBytes(bytes, album: t.appTitle);
        _showMessage(t.savedGallery);
        AdService.instance.registerAction();
      } else {
        _showMessage(t.imageNotCaptured, isError: true);
      }
    } on GalException catch (e) {
      _showMessage("${t.permissionError}: $e", isError: true);
    } catch (e) {
      _showMessage("${t.unexpectedError}: $e", isError: true);
    }
  }

  Future<void> _shareQrImage() async {
    final t = AppLocalizations.of(context)!;
    try {
      final Uint8List? bytes = await screenshotController.capture();
      if (bytes != null) {
        AdService.instance.registerAction();
        await QrDao.shareQrImage(bytes);
      } else {
        _showMessage(t.imageCreateError, isError: true);
      }
    } catch (e) {
      _showMessage("${t.genericError}: $e", isError: true);
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const QrCodePast()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage()));
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _showFavoriteNameDialog(String qrData) {
    final t = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Text(t.addToFavorite, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: t.favoriteHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text(t.cancel, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  String name = nameController.text.trim();
                  if (name.isEmpty) name = t.unnamedQr;
                  AdService.instance.registerAction();
                  await FavoriteService.addFavorite(name, qrData);

                  Navigator.pop(context);
                  _showSuccessDialog(t.addedToFavorites);
                },
                child: Text(t.save, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          t.appTitle,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesPage())
              );
            },
            icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
          ),
          IconButton(
            onPressed: () => SystemNavigator.pop(),
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.black54),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: t.enterTextHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                          _qrData = null;
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  String text = _controller.text.trim();
                  if (text.isEmpty) {
                    _showMessage(t.pleaseEnterText, isError: true);
                    return;
                  }

                  FocusScope.of(context).unfocus();

                  setState(() {
                    _qrData = text;
                  });

                  await _processQrCreation(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(t.createQr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 40),

              if (_qrData != null) ...[
                Column(
                  children: [
                    Screenshot(
                      controller: screenshotController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.download_rounded,
                          label: t.download,
                          onTap: saveImageToGallery,
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          label: t.share,
                          onTap: _shareQrImage,
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.favorite,
                          label: t.favorite,
                          color: Colors.pinkAccent,
                          onTap: () {
                            if (_qrData != null) {
                              _showFavoriteNameDialog(_qrData!);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                _buildPlaceholderAnimation(context),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBannerLoaded)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          const SizedBox(height: 35),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _onBottomNavTap(index);
            },
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.history), label: t.history),
              BottomNavigationBarItem(icon: const Icon(Icons.add), label: t.create),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), label: t.favorite), // QR Tarama yerine Favoriler Sayfası bağlandı
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAnimation(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.waitingInput,
            style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}