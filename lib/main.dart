import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import ini
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import 'services/database_service.dart';

void main() async {
  // Menyiapkan plugin sistem sebelum aplikasi dijalankan
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load file .env agar API Key Gemini bisa dibaca
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully! ✅");
  } catch (e) {
    debugPrint("Error loading .env file: $e ❌");
  }

  // Inisialisasi Database (termasuk Notifikasi di dalamnya)
  await Get.putAsync(() => DatabaseService().init());

  runApp(const EcoStepApp());
}

class EcoStepApp extends StatelessWidget {
  const EcoStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EcoStep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
      ),

      // Menggunakan route yang sudah dipisah
      initialRoute: AppRoutes.initial,
      getPages: AppRoutes.routes,
      initialBinding: InitialBinding(),
    );
  }
}
