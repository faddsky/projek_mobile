import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
    // Memanggil fungsi load dengan sedikit delay agar UI siap dulu
    Future.delayed(Duration(milliseconds: 500), () {
      loadModel();
    });
  }

  // 1. Memuat Model dan Label
  Future<void> loadModel() async {
    try {
      print("Starting to load Model v3... 🔄");

      // Load Label
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      print("Labels loaded: ${_labels?.length} classes");

      // Load Model Biner
      final byteData = await rootBundle.load('assets/models/model_ecostep_v3_fixed.tflite');
      print("Model bytes loaded: ${byteData.lengthInBytes} bytes");

      // BARIS KRUSIAL: Memasukkan byte data ke Interpreter
      _interpreter = Interpreter.fromBuffer(byteData.buffer.asUint8List());

      print("Model & Labels Loaded Successfully! 🚀✅");
    } catch (e) {
      print("Error loading model detail: $e");
      resultLabel.value = "Gagal memuat mesin AI";
    }
  }

  // 2. Membuka Kamera/Galeri
  Future<void> pickImageFromSource({required bool isCamera}) async {
    if (isCamera) {
      var status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        Get.snackbar(
          "Izin Ditolak",
          "Buka pengaturan HP dan aktifkan izin kamera manual ya.",
          snackPosition: SnackPosition.BOTTOM,
        );
        openAppSettings();
        return;
      }
      if (!status.isGranted) return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        // Jeda sebentar biar UI update preview gambar
        Future.delayed(Duration(milliseconds: 300), () {
          analyzeImage();
        });
      }
    } catch (e) {
      print("Gagal mengambil gambar: $e");
    }
  }

  // 3. Fungsi Inferensi AI
  Future<void> analyzeImage() async {
    if (selectedImagePath.value.isEmpty) return;

    // Pastikan interpreter siap, kalau null coba muat ulang sekali lagi
    if (_interpreter == null || _labels == null) {
      print("AI belum siap. Mencoba muat ulang...");
      await loadModel();
      if (_interpreter == null) {
        resultLabel.value = "Mesin AI masih belum siap";
        return;
      }
    }

    isLoading.value = true;
    try {
      var imageFile = File(selectedImagePath.value);
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? rawImage = img.decodeImage(imageBytes);

      if (rawImage == null) return;

      const int inputSize = 224;
      img.Image resizedImage = img.copyResize(
        rawImage,
        width: inputSize,
        height: inputSize,
      );

      var input = imageToByteListFloat32(resizedImage, inputSize);

      // Siapkan wadah output sesuai jumlah kategori di labels.txt
      var output = List.filled(1 * _labels!.length, 0.0)
          .reshape([1, _labels!.length]);

      // EKSEKUSI MODEL
      _interpreter!.run(input, output);

      List<double> probabilities = List<double>.from(output[0]);
      double highestProb = -1.0;
      int highestIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > highestProb) {
          highestProb = probabilities[i];
          highestIndex = i;
        }
      }

      // Update UI secara reaktif
      resultLabel.value = _labels![highestIndex].toUpperCase();
      confidence.value = highestProb * 100;

      print("Result: ${resultLabel.value} (${confidence.value.toStringAsFixed(2)}%)");

      // Simpan ke Database
      try {
        final db = Get.find<DatabaseService>();
        // Hapus 'await' di sini karena saveScanResult bertipe 'void'
        db.saveScanResult(
          resultLabel.value,
          highestProb,
          "Terdeteksi via EcoStep AI v3",
        );
      } catch (dbError) {
        print("Database save error: $dbError");
      }

    } catch (e) {
      print("Error saat analisa: $e");
      resultLabel.value = "Gagal menganalisa gambar";
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Preprocessing & Normalisasi standar MobileNet (-1 ke 1)
  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);

        // Normalisasi standar: (pixel - 127.5) / 127.5
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