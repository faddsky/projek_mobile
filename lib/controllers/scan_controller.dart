import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  var isLowConfidence = false.obs;
  final double threshold = 75.0;

  var funFact = "Sedang memikirkan fakta menarik...".obs;
  var isAiLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 500), () {
      loadModel();
    });
  }

  Future<void> loadModel() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Gunakan nama file model terbaru kamu
      final byteData = await rootBundle.load(
        'assets/models/model_ecostep_final.tflite',
      );
      _interpreter = Interpreter.fromBuffer(byteData.buffer.asUint8List());
      debugPrint("✅ Model & Labels Loaded! Jumlah Label: ${_labels!.length}");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      resultLabel.value = "Gagal memuat mesin AI";
    }
  }

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
        imageQuality: 100,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        analyzeImage();
      }
    } catch (e) {
      debugPrint("❌ Gagal mengambil gambar: $e");
    }
  }

  Future<void> analyzeImage() async {
    if (selectedImagePath.value.isEmpty || _interpreter == null) return;

    isLoading.value = true;
    try {
      var imageFile = File(selectedImagePath.value);
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? rawImage = img.decodeImage(imageBytes);

      if (rawImage == null) return;

      const int inputSize = 224;

      // 1. CENTER CROP (Sinkron dengan crop_to_aspect_ratio=True di notebook)
      int edgeSize = rawImage.width < rawImage.height ? rawImage.width : rawImage.height;
      img.Image croppedImage = img.copyCrop(
        rawImage,
        x: (rawImage.width - edgeSize) ~/ 2,
        y: (rawImage.height - edgeSize) ~/ 2,
        width: edgeSize,
        height: edgeSize,
      );

      // 2. RESIZE ke 224x224
      img.Image resizedImage = img.copyResize(
        croppedImage,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      // 3. INPUT PREPARATION
      // Mengirim nilai 0-255 karena model sudah punya layer Rescaling internal
      var input = imageToByteListFloat32(resizedImage, inputSize);

      // 4. OUTPUT BUFFER
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      // 5. RUN INTERPRETER
      _interpreter!.run(input, output);

      List<double> probabilities = List<double>.from(output[0]);
      debugPrint("🔍 Hasil Scan Probabilitas: $probabilities");

      double highestProb = -1.0;
      int highestIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > highestProb) {
          highestProb = probabilities[i];
          highestIndex = i;
        }
      }

      // 6. UPDATE UI
      resultLabel.value = _labels![highestIndex].toUpperCase();
      confidence.value = highestProb * 100;
      isLowConfidence.value = confidence.value < threshold;

      // Simpan ke Database
      try {
        final db = Get.find<DatabaseService>();
        db.saveScanResult(
          resultLabel.value,
          highestProb,
          isLowConfidence.value ? "Hasil Kurang Yakin" : "Terdeteksi Akurat",
        );
      } catch (dbError) {
        debugPrint("⚠️ Gagal simpan ke DB: $dbError");
      }

      // Gemini Fact (Opsional)
      // fetchFunFact(resultLabel.value);
      funFact.value = "Fitur Eco-Fact sedang dinonaktifkan.";

    } catch (e) {
      debugPrint("❌ Error Analisis: $e");
      resultLabel.value = "Gagal menganalisa";
    } finally {
      isLoading.value = false;
    }
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);

        // KITA KIRIM NILAI MENTAH 0-255
        // Layer Rescaling(1./127.5, offset=-1) di model kamu yang akan menormalkannya
        buffer[pixelIndex++] = pixel.r.toDouble();
        buffer[pixelIndex++] = pixel.g.toDouble();
        buffer[pixelIndex++] = pixel.b.toDouble();
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future<void> fetchFunFact(String category) async {
    isAiLoading.value = true;
    funFact.value = "Mencari fakta unik...";
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
      if (apiKey.isEmpty) return;

      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      final prompt = "Berikan 1 fun fact singkat dampak lingkungan sampah $category. Bahasa Indonesia, maks 20 kata.";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        funFact.value = response.text!.trim();
      }
    } catch (e) {
      funFact.value = "Mari jaga lingkungan kita bersama!";
    } finally {
      isAiLoading.value = false;
    }
  }

  @override
  void onClose() {
    _interpreter?.close();
    super.onClose();
  }
}