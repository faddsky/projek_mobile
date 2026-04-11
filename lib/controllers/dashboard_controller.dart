import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:projek_mobile/services/database_service.dart'; // Import DatabaseService kamu

class DashboardController extends GetxController {
  var stepCount = 0.obs;
  var carbonSaved = 0.0.obs;
  
  DateTime _lastStepTime = DateTime.now();
  
  // Threshold 10.8: Pas untuk jalan santai (tidak terlalu sensitif tapi peka)
  final double threshold = 10.8; 
  final Duration stepDelay = const Duration(milliseconds: 450); 

  @override
  void onInit() {
    super.onInit();
    _initPedometer();
    
    // --- TAMBAHAN: CEK NOTIFIKASI TIPS SAAT DIBUKA ---
    // Fungsi ini akan mengirim tips harian otomatis ke HP kamu
    Get.find<DatabaseService>().checkAndSendGreenTip();
  }

  void _initPedometer() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > threshold) {
        DateTime now = DateTime.now();
        if (now.difference(_lastStepTime) > stepDelay) {
          stepCount.value++;
          carbonSaved.value = stepCount.value * 0.04; 
          _lastStepTime = now;
        }
      }
    });
  }

  // --- TAMBAHAN: FUNGSI RESET (OPSIONAL) ---
  void resetSteps() {
    stepCount.value = 0;
    carbonSaved.value = 0.0;
  }

  void scanWaste() {
    Get.snackbar(
      "Eco Scanner", 
      "Membuka Kamera...",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
    );
  }
}