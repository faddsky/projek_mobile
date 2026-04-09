import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/scan_controller.dart';

class ScanPage extends GetView<ScanController> {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Eco Scan", 
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- AREA PREVIEW GAMBAR ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFF6B8E23), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Obx(() {
                      if (controller.selectedImagePath.value.isEmpty) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance_rounded, size: 80, color: Colors.white24),
                            SizedBox(height: 15),
                            Text(
                              "Belum ada gambar yang diambil",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        );
                      } else {
                        return Image.file(
                          File(controller.selectedImagePath.value),
                          fit: BoxFit.cover,
                        );
                      }
                    }),
                  ),
                ),
              ),

              // --- PANEL KONTROL ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Pilih Sumber Gambar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.photo_library_rounded,
                          label: "Galeri",
                          color: Colors.blue[50]!,
                          iconColor: Colors.blue,
                          onTap: () => controller.pickImageFromSource(isCamera: false),
                        ),
                        _buildActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: "Kamera",
                          color: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF6B8E23),
                          onTap: () => controller.pickImageFromSource(isCamera: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // Tombol Analisis (Hanya muncul jika gambar sudah ada)
                    Obx(() => controller.selectedImagePath.value.isNotEmpty
                      ? SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8E23),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () => _showResultSheet(context),
                            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                            label: const Text(
                              "Lihat Hasil Analisis",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : const SizedBox(height: 55)),
                  ],
                ),
              ),
            ],
          ),

          // --- LOADING OVERLAY ---
          Obx(() => controller.isLoading.value 
            ? Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B8E23)),
                ),
              ) 
            : const SizedBox()),
        ],
      ),
    );
  }

  // --- MODAL HASIL ANALISIS ---
  void _showResultSheet(BuildContext context) {
    // Karena analyzeImage sudah dipanggil di pickImageFromSource, 
    // kita cukup menampilkan datanya saja di sini.
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 5, 
              decoration: BoxDecoration(
                color: Colors.grey[300], 
                borderRadius: BorderRadius.circular(10)
              )
            ),
            const SizedBox(height: 20),
            const Text("Hasil Identifikasi", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Menggunakan Obx agar UI update saat variabel di controller berubah
            Obx(() => Text(
              controller.resultLabel.value.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF6B8E23)
              ),
            )),
            const SizedBox(height: 8),
            Obx(() => Text(
              "Tingkat Keyakinan: ${(controller.confidence.value * 100).toStringAsFixed(1)}%",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            )),
            
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Get.back(),
                child: const Text("Tutup", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 35, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}