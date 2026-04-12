import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Ditambahkan untuk debugPrint
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScanController extends GetxController {
  Interpreter? _interpreter;
  List<String>? _labels;

  var selectedImagePath = ''.obs;
  var resultLabel = "Menunggu scan...".obs;
  var confidence = 0.0.obs;
  var isLoading = false.obs;

  // Variabel untuk Gemini LLM
  var funFact = "Sedang memikirkan fakta menarik...".obs;
  var isAiLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 500), () {
      loadModel();
    });
  }

  // 1. Memuat Model TFLite
  Future<void> loadModel() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final byteData = await rootBundle.load(
        'assets/models/model_ecostep_v3_fixed.tflite',
      );
      _interpreter = Interpreter.fromBuffer(byteData.buffer.asUint8List());
      debugPrint("✅ Model & Labels Loaded Successfully! 🚀");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      resultLabel.value = "Gagal memuat mesin AI";
    }
  }

  // 2. Pilih Gambar
  Future<void> pickImageFromSource({required bool isCamera}) async {
    if (isCamera) {
      var status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return;
      }
      if (!status.isGranted) return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50, // Sudah bagus untuk mengurangi beban memori
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        // Beri jeda sedikit agar UI tidak freeze saat transisi
        Future.delayed(const Duration(milliseconds: 300), () {
          analyzeImage();
        });
      }
    } catch (e) {
      debugPrint("❌ Gagal mengambil gambar: $e");
    }
  }

  // 3. Analisis Gambar (TFLite)
  Future<void> analyzeImage() async {
    if (selectedImagePath.value.isEmpty || _interpreter == null) return;

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

      var output = List.filled(
        1 * _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);
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

      resultLabel.value = _labels![highestIndex].toUpperCase();
      confidence.value = highestProb * 100;

      // Simpan ke Database
      try {
        final db = Get.find<DatabaseService>();
        db.saveScanResult(
          resultLabel.value,
          highestProb,
          "Terdeteksi via EcoStep AI v3",
        );
      } catch (dbError) {
        debugPrint("⚠️ Gagal simpan ke DB: $dbError");
      }

      // Panggil Gemini untuk Fun Fact
      // fetchFunFact(resultLabel.value);
      funFact.value = "Fitur AI Fun Fact sedang dinonaktifkan.";
    } catch (e) {
      debugPrint("❌ Error Analisis: $e");
      resultLabel.value = "Gagal menganalisa";
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Gemini AI Fun Fact (VERSI DEBUG LENGKAP)
  Future<void> fetchFunFact(String category) async {
    isAiLoading.value = true;
    funFact.value = "Mencari fakta unik...";

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

      if (apiKey.isEmpty) {
        debugPrint("❌ DEBUG_ERROR: API Key tidak ditemukan di .env!");
        funFact.value = "Konfigurasi API salah.";
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );

      final prompt =
          "Berikan 1 fun fact singkat tentang dampak lingkungan sampah $category. Gunakan Bahasa Indonesia, maksimal 20 kata.";
      final content = [Content.text(prompt)];

      debugPrint("🚀 DEBUG: Menghubungi Gemini untuk kategori: $category...");

      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        funFact.value = response.text!.trim();
        debugPrint("✅ DEBUG_SUCCESS: Respon Gemini diterima.");
      } else {
        debugPrint("⚠️ DEBUG_WARNING: Respon Gemini kosong.");
        funFact.value = "Mari jaga lingkungan kita bersama!";
      }
    } catch (e, stacktrace) {
      debugPrint("--------------------------------------------------");
      debugPrint("❌ DEBUG_ERROR GEMINI TERDETEKSI!");
      debugPrint("Pesan Error: $e");
      debugPrint("Stacktrace: $stacktrace");
      debugPrint("--------------------------------------------------");

      funFact.value = "Fakta tidak tersedia (cek koneksi).";
    } finally {
      isAiLoading.value = false;
    }
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
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
