
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Helpdatabase{

  static final String databaseName = "pastqrTable2.db";

  static Future<Database> veritabaniErisim() async {
    String databaseWay = join(await getDatabasesPath(), databaseName);

    if(await databaseExists(databaseWay)){//Veritabanı var mı yok mu kontrolü
      print("Veri tabanı zaten var.Kopyalamaya gerek yok");
    }else{
      //assetten veritabanının alınması
      ByteData data = await rootBundle.load("database-2/$databaseName");
      //Veritabanının kopyalama için byte dönüşümü
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      //Veritabanının kopyalanması.
      await File(databaseWay).writeAsBytes(bytes,flush: true);
      print("Veri tabanı kopyalandı");
    }
    //Veritabanını açıyoruz.
    return openDatabase(databaseWay);
  }

}



