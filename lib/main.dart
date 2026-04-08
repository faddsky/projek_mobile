import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Solusi untuk GetStorage merah
import 'routes/app_pages.dart';             // Solusi untuk AppRoutes merah
import 'bindings/initial_binding.dart';     // Solusi untuk InitialBinding merah

void main() async {
  await GetStorage.init();
  runApp(const EcoStepApp());
}

class EcoStepApp extends StatelessWidget {
  const EcoStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EcoStep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(/* ... tema sage green kamu ... */),
      
      // Menggunakan route yang sudah dipisah
      initialRoute: AppRoutes.INITIAL,
      getPages: AppRoutes.routes,
      initialBinding: InitialBinding(),
    );
  }
}