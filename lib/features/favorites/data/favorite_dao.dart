import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _key = "favorite_qrs";

  // YENİ: İsimle Birlikte Favoriye Ekle
  static Future<void> addFavorite(String title, String data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    // Aynı QR verisi varsa önce sil (üzerine yazmak için)
    favorites.removeWhere((item) {
      try {
        final map = jsonDecode(item);
        return map['data'] == data;
      } catch (e) {
        return item == data; // Eski formattaysa
      }
    });

    final newItem = jsonEncode({'title': title, 'data': data});
    favorites.add(newItem);
    await prefs.setStringList(_key, favorites);
  }

  // YENİ: Favoriden Çıkar (Data'ya göre bulup siler)
  static Future<void> removeFavorite(String data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    favorites.removeWhere((item) {
      try {
        final map = jsonDecode(item);
        return map['data'] == data;
      } catch (e) {
        return item == data;
      }
    });
    await prefs.setStringList(_key, favorites);
  }

  // Favori mi kontrol et
  static Future<bool> isFavorite(String data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    for (String item in favorites) {
      try {
        final map = jsonDecode(item);
        if (map['data'] == data) return true;
      } catch (e) {
        if (item == data) return true;
      }
    }
    return false;
  }

  // GÜNCELLENDİ: Artık Map listesi dönüyor (Başlık ve Veri beraber)
  static Future<List<Map<String, String>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_key) ?? [];

    List<Map<String, String>> result = [];

    for (String item in favorites) {
      try {
        final map = jsonDecode(item);
        result.add({
          'title': map['title'].toString(),
          'data': map['data'].toString(),
        });
      } catch (e) {
        // Eski, isimsiz kayıtlar varsa çökmemesi için
        result.add({
          'title': 'İsimsiz QR',
          'data': item,
        });
      }
    }
    return result.reversed.toList(); // En son eklenen en üstte çıksın
  }
}