import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  int _actionCounter = 0;
  int _dailyAdCount = 0;

  DateTime _appStartTime = DateTime.now();
  DateTime _lastAdTime = DateTime.fromMillisecondsSinceEpoch(0);

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  static const int maxDailyAds = 5;
  static const int minSecondsAfterOpen = 15;
  static const int minSecondsBetweenAds = 45;

  void initialize() {
    _loadInterstitialAd();
  }

  void registerAction() {
    _actionCounter++;

    if (_actionCounter >= 3) {
      _actionCounter = 0;
      _showInterstitialAdSafely();
    }
  }

  void _loadInterstitialAd() {
    if (_isAdLoading) return;

    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: "your_id",
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          print("Interstitial yüklenemedi: $error");
        },
      ),
    );

  }

  void _showInterstitialAdSafely() {
    final now = DateTime.now();

    if (now.difference(_appStartTime).inSeconds < minSecondsAfterOpen) return;
    if (_dailyAdCount >= maxDailyAds) return;
    if (now.difference(_lastAdTime).inSeconds < minSecondsBetweenAds) return;

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;

      _dailyAdCount++;
      _lastAdTime = now;

      _loadInterstitialAd();
    }
  }
}
