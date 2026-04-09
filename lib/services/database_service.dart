import 'package:flutter/material.dart'; // Tambahkan ini untuk debugPrint
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseService extends GetxService {
  static const String authBox = 'auth_box';
  static const String profileBox = 'profile_box';
  static const String historyBox = 'history_box';
  static const String activityBox = 'activity_box';
  static const String sessionBox = 'session_box';

  Future<DatabaseService> init() async {
    await Hive.initFlutter();
    
    await Hive.openBox(authBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(historyBox);
    await Hive.openBox(activityBox);
    await Hive.openBox(sessionBox);
    
    return this;
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); 
    return sha256.convert(bytes).toString();
  }

  void saveScanResult(String label, double confidence, String funFact) {
    var box = Hive.box(historyBox);
    box.add({
      'label': label,
      'confidence': confidence,
      'funFact': funFact,
      'dateTime': DateTime.now().toString(),
    });
  }

  int getSteps() => Hive.box(activityBox).get('steps', defaultValue: 0);
  
  void saveSteps(int steps) => Hive.box(activityBox).put('steps', steps);

  // --- TAMBAHKAN DI SINI ---
  // Fungsi "Sapu Jagat" untuk monitor semua isi box di Debug Console
  void debugCekSemuaBox() {
    List<String> semuaBox = [authBox, profileBox, historyBox, activityBox, sessionBox];
    
    debugPrint("========== MONITORING DATABASE ECOSTEP ==========");
    
    for (String namaBox in semuaBox) {
      if (Hive.isBoxOpen(namaBox)) {
        var box = Hive.box(namaBox);
        debugPrint("📦 BOX: $namaBox (${box.length} data)");
        
        if (box.isEmpty) {
          debugPrint("   - Status: Kosong");
        } else {
          box.toMap().forEach((key, value) {
            debugPrint("   key: $key => value: $value");
          });
        }
      } else {
        debugPrint("❌ BOX: $namaBox (Belum terbuka)");
      }
      debugPrint("------------------------------------------------");
    }
    
    debugPrint("================================================");
  }
}