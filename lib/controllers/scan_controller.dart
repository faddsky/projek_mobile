import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; 
import '../services/database_service.dart';
import 'package:permission_handler/permission_handler.dart'; // Import ini penting

class ScanController extends GetxController {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  var selectedImagePath = ''.obs;
  var resultLabel = "Menunggu scan...".obs;
  var confidence = 0.0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadModel();
  }

  // 1. Memuat Model dan Label
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_ecostep_v2.tflite');
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      print("Model & Labels loaded successfully! 🚀");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // 2. Membuka Kamera/Galeri dengan Cek Izin
  Future<void> pickImageFromSource({required bool isCamera}) async {
    // CEK IZIN TERLEBIH DAHULU
    if (isCamera) {
      var status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        Get.snackbar("Izin Ditolak", "Buka pengaturan HP dan aktifkan izin kamera manual ya, Mel.",
            snackPosition: SnackPosition.BOTTOM);
        openAppSettings();
        return;
      }
      if (!status.isGranted) return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50, // Agar proses resize tidak berat
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        // Jeda sedikit agar UI loading muncul dulu
        Future.delayed(const Duration(milliseconds: 200), () => analyzeImage());
      }
    } catch (e) {
      print("Gagal mengambil gambar: $e");
      Get.snackbar("Error", "Gagal membuka kamera/galeri");
    }
  }

  // 3. Fungsi Inferensi AI
  Future<void> analyzeImage() async {
    if (selectedImagePath.value.isEmpty || _interpreter == null) return;

    isLoading.value = true;
    try {
      var imageFile = File(selectedImagePath.value);
      Uint8List imageBytes = imageFile.readAsBytesSync();
      
      img.Image? rawImage = img.decodeImage(imageBytes);
      if (rawImage == null) return;

      const int inputSize = 224; // Sesuaikan dengan input modelmu
      img.Image resizedImage = img.copyResize(rawImage, width: inputSize, height: inputSize);

      var input = imageToByteListFloat32(resizedImage, inputSize);
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      _interpreter!.run(input, output);

      List<double> probabilities = List<double>.from(output[0]);
      double highestProb = 0.0;
      int highestIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > highestProb) {
          highestProb = probabilities[i];
          highestIndex = i;
        }
      }

      resultLabel.value = _labels![highestIndex];
      confidence.value = highestProb;

      // Simpan hasil ke database (Hive)
      Get.find<DatabaseService>().saveScanResult(
        resultLabel.value,
        confidence.value,
        "Terdeteksi via EcoStep AI",
      );

    } catch (e) {
      print("Error analyze: $e");
      resultLabel.value = "Gagal memproses gambar";
    } finally {
      isLoading.value = false;
    }
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  void onClose() {
    _interpreter?.close();
    super.onClose();
  }
}