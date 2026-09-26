<div align="center">

  # 📱 Smart QR Scanner & Generator Platform
  ### Offline-First, Feature-First Clean Architecture Powered by Flutter & AdMob

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![SQLite](https://img.shields.io/badge/SQLite-Local_DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
  [![AdMob](https://img.shields.io/badge/Google_AdMob-Monetization-EA4335?style=for-the-badge&logo=googleadmob&logoColor=white)](https://admob.google.com/)
  [![Architecture](https://img.shields.io/badge/Architecture-Feature--First_Clean-blueviolet?style=for-the-badge)](#-technical-architecture)
  [![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/YOUR_LINKEDIN_USERNAME)

</div>

---

## ⚡ Executive Summary

**Smart QR Scanner & Generator** is a modular, high-performance mobile application designed for ultra-fast QR and barcode scanning, custom QR code generation, and secure local data persistence via SQLite.

Built following industry-standard **Feature-First Clean Architecture**, the application features Google AdMob monetization, internationalization support (Localization - EN/TR), and an offline-first data layer.

---

## 🔑 Key Features & Capabilities

* **⚡ Fast & Instant Scanning:** Millisecond-level QR code and barcode recognition with active auto-focus camera integration.
* **✏️ Custom QR Generator:** Create personalized QR codes for URLs, plain text, contact cards, and Wi-Fi configurations.
* **💾 Offline Persistence & DAO Architecture (SQLite):** Securely store scan history and bookmarked items on-device without requiring an internet connection (`qr_dao`, `favorite_dao`).
* **⭐ Favorites & History Management:** Categorize, bookmark, filter, and manage scanned codes seamlessly.
* **💰 AdMob Monetization Integration:** Isolated Banner and Interstitial ad implementations via `ad_service` without degrading UI performance or UX.
* **🌐 Multi-Language Support (i10n):** Full internationalization support with English and Turkish dictionaries (`app_en.arb`, `app_tr.arb`).

---

## 🏗 Technical Architecture

The project strictly adheres to **Feature-First Clean Architecture** principles for maximum scalability, testability, and code maintainability.

```text
lib/
├── main.dart                           # Application Entrypoint & App Configuration
│
├── core/                               # Central Infrastructure Across Features
│   ├── database/
│   │   └── database_helper.dart        # SQLite Central Helper & Database Initialization
│   └── services/
│       └── ad_service.dart             # Isolated AdMob Service Engine
│
├── l10n/                               # App Internationalization (i10n)
│   ├── app_en.arb                      # English Dictionary
│   └── app_tr.arb                      # Turkish Dictionary
│
└── features/                           # Business Logic Modules
    ├── qr_scanner/                     # Core Scanning & QR Creation Module
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── qr_model.dart       # QR Data Model
    │   │   └── qr_dao.dart             # QR Data Access Object (SQLite Operations)
    │   └── presentation/
    │       └── home_page.dart          # Main Dashboard & Scanner View
    │
    ├── favorites/                      # Bookmarked QR Codes Module
    │   ├── data/
    │   │   └── favorite_dao.dart       # Favorite DAO Operations
    │   └── presentation/
    │       └── favorites_page.dart     # Favorites Screen
    │
    └── history/                        # Scan Logs & History Module
        └── presentation/
            └── qr_history_page.dart    # History Listing Screen
