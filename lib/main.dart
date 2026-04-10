import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart'; 
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart'; 
import 'services/database_service.dart' ; 

void main() async {
  // --- TAMBAHAN UNTUK NOTIFIKASI ---
  // Menyiapkan plugin sistem sebelum aplikasi dijalankan
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Database (termasuk Notifikasi di dalamnya)
  await Get.putAsync(() => DatabaseService().init());
  // ---------------------------------

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B8E23),
        ),
      ),
      
      // Menggunakan route yang sudah dipisah
      initialRoute: AppRoutes.INITIAL,
      getPages: AppRoutes.routes,
      initialBinding: InitialBinding(),
    );
  }
}