import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DashboardController extends GetxController {
  // Variabel reaktif untuk update UI otomatis
  var stepCount = 0.obs;
  var carbonSaved = 0.0.obs;
  
  // Variabel untuk menyimpan waktu langkah terakhir
  DateTime _lastStepTime = DateTime.now();
  
  // --- SETTING KALIBRASI ---
  // Kita pakai threshold 11.0. 
  // (Gravitasi bumi normal adalah 9.8. Saat melangkah, angkanya akan naik ke 11-13)
  final double threshold = 20.0; 
  
  // Jeda waktu antar langkah (500ms = setengah detik)
  // Biar kalau HP goyang-goyang di saku nggak dihitung berkali-kali dalam satu langkah
  final Duration stepDelay = const Duration(milliseconds: 500); 

  @override
  void onInit() {
    super.onInit();
    _initPedometer();
  }

  void _initPedometer() {
    // Mengambil data dari sensor Akselerometer
    accelerometerEvents.listen((AccelerometerEvent event) {
      
      // Rumus Magnitude (Total kekuatan guncangan dari segala arah)
      // Magnitude = sqrt(x^2 + y^2 + z^2)
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // LOGIKA BARU:
      // Jika guncangan total (magnitude) menembus angka 11.0, berarti ada hentakan langkah.
      if (magnitude > threshold) {
        DateTime now = DateTime.now();
        
        // Cek apakah sudah lewat dari jeda waktu (stepDelay)
        if (now.difference(_lastStepTime) > stepDelay) {
          stepCount.value++;
          
          // Hitung penghematan karbon (asumsi 1 langkah = 0.04g CO2)
          carbonSaved.value = stepCount.value * 0.04; 
          
          _lastStepTime = now;
          
          // Debugging di terminal (Opsional, bisa dihapus nanti)
          debugPrint("Langkah terdeteksi! Total: ${stepCount.value}");
        }
      }
    });
  }


}