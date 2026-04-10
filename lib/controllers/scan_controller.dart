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
    loadModel();
  }

  // 1. Memuat Model dan Label
  Future<void> loadModel() async {
    try {
      // 1. Ambil data mentah dari asset
      final byteData = await rootBundle.load(
        'assets/models/model_ecostep_v2.tflite',
      );

      // 2. Ubah ke Uint8List (data biner mentah)
      final modelBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // 3. Load ke interpreter menggunakan Buffer
      _interpreter = Interpreter.fromBuffer(modelBytes);

      // 4. Load Label
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();

      print(
        "Model Loaded Successfully via Buffer! 🚀✅ (Size: ${modelBytes.length} bytes)",
      );
    } catch (e) {
      print("Error loading model: $e");
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
          "Buka pengaturan HP dan aktifkan izin kamera manual ya, Mel.",
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
        analyzeImage(); // Langsung eksekusi
      }
    } catch (e) {
      print("Gagal mengambil gambar: $e");
    }
  }

  // 3. Fungsi Inferensi AI
  Future<void> analyzeImage() async {
    if (selectedImagePath.value.isEmpty ||
        _interpreter == null ||
        _labels == null) {
      print("Persiapan belum lengkap (Model/Labels/Image NULL)");
      return;
    }

    isLoading.value = true;
    try {
      var imageFile = File(selectedImagePath.value);
      Uint8List imageBytes = imageFile.readAsBytesSync();

      img.Image? rawImage = img.decodeImage(imageBytes);
      if (rawImage == null) return;

      // Model biasanya butuh 224x224
      const int inputSize = 224;
      img.Image resizedImage = img.copyResize(
        rawImage,
        width: inputSize,
        height: inputSize,
      );

      // Konversi gambar ke format yang dimengerti AI
      var input = imageToByteListFloat32(resizedImage, inputSize);

      // Siapkan wadah untuk hasil (Output)
      var output = List.filled(
        1 * _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);

      // JALANKAN MESIN AI
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

      // Update UI secara reaktif
      resultLabel.value = _labels![highestIndex].toUpperCase();
      confidence.value = highestProb * 100; // Ubah ke persen biar enak dibaca

      // Simpan hasil ke database
      final db = Get.find<DatabaseService>();
      db.saveScanResult(
        resultLabel.value,
        confidence.value / 100,
        "Terdeteksi via EcoStep AI",
      );
    } catch (e) {
      print("Error analyze: $e");
      resultLabel.value = "Terjadi kesalahan saat klasifikasi";
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Preprocessing Gambar (Normalisasi 0-1 atau -1 ke 1)
  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);

        // Normalisasi: (Nilai - 127.5) / 127.5 membuat rentang pixel jadi -1 sampai 1
        // Sesuai dengan standar Teachable Machine / TensorFlow
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
