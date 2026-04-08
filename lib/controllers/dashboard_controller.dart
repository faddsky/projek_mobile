import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class DashboardController extends GetxController {
  // Variabel reaktif GetX
  var stepCount = 0.obs;
  var carbonSaved = 0.0.obs; // dalam gram
  var isScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    initAccelerometer();
  }

  void initAccelerometer() {
    // Logika sederhana hitung langkah dari getaran XYZ
    accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (acceleration > 12) { // Threshold sederhana untuk 1 langkah
        stepCount.value++;
        carbonSaved.value = stepCount.value * 0.04; // Asumsi 1 langkah hemat 0.04g CO2
      }
    });
  }

  void scanWaste() {
    // Nanti diintegrasikan dengan Image Picker & API ML
    isScanning.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      isScanning.value = false;
      Get.snackbar("Eco AI", "Berhasil mendeteksi: Sampah Plastik (Anorganik)");
    });
  }
}