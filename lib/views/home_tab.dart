import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_mobile/services/api_service.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/dashboard_controller.dart';
import 'scan_page.dart';
import '../controllers/scan_controller.dart';
import 'alarm_page.dart'; // Import halaman daftar alarm kamu

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Fungsi Salam Dinamis berdasarkan waktu HP
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return "Selamat pagi,";
    if (hour < 15) return "Selamat siang,";
    if (hour < 18) return "Selamat sore,";
    return "Selamat malam,";
  }

  // Fungsi navigasi ke halaman DAFTAR ALARM (Bukan langsung tambah)
  void _goToAlarmPage() {
    Get.to(() => const AlarmPage());
  }

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller pedometer
    final controller = Get.put(DashboardController());

    // Ambil Username dari Database Hive
    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String? currentUser = sessionBox.get('currentUser'); 
    var authBox = Hive.box(DatabaseService.authBox);
    var userData = authBox.get('user_$currentUser');
    String username = userData?['username'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dinamis (Salam & Nama)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreeting(),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        "$username ✨",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 30,
                    color: Color(0xFF6B8E23),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Card Pedometer Aesthetic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8DAA91), Color(0xFF6B8E23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Langkah Kakimu Hari Ini",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Text(
                        "${controller.stepCount.value}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => Text(
                        "🌱 Hemat ${controller.carbonSaved.value.toStringAsFixed(2)}g CO2",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan ke Cloud
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ApiService.sendEcoData(
                            "Aktivitas Berjalan",
                            controller.stepCount.value,
                          );
                          Get.snackbar("Berhasil!", "Data tersimpan di Cloud Google ☁️",
                              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white);
                          setState(() {}); 
                        } catch (e) {
                          Get.snackbar("Error", "Gagal konek server Cloud, Dil! 😅");
                        }
                      },
                      icon: const Icon(Icons.cloud_upload, color: Color(0xFF6B8E23)),
                      label: const Text("Simpan ke Cloud", style: TextStyle(color: Color(0xFF6B8E23))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bagian Tool Cards
              const Text(
                "Eco AI Tools",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildToolCard(
                      "Scan Sampah",
                      Icons.camera_enhance_rounded,
                      Colors.orange[50]!,
                      Colors.orange,
                      () {
                        Get.to(
                          () => const ScanPage(),
                          binding: BindingsBuilder(() {
                            Get.put(ScanController());
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  // CARD ALARM (Buka AlarmPage yang berisi daftar alarm)
                  Expanded(
                    child: _buildToolCard(
                      "Jadwal Sampah",
                      Icons.alarm_on_rounded,
                      Colors.blue[50]!,
                      Colors.blue,
                      () => _goToAlarmPage(), 
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // RIWAYAT DARI CLOUD
              const Text(
                "Riwayat Cloud Terbaru",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<dynamic>>(
                future: ApiService.fetchData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    var items = snapshot.data!.reversed.toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length > 5 ? 5 : items.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.green.shade50),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.cloud_done, color: Colors.green),
                            title: Text(items[index]['aktivitas'] ?? "Aktivitas"),
                            subtitle: Text("${items[index]['langkah']} Langkah"),
                            trailing: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text("Belum ada data di Cloud", style: TextStyle(color: Colors.grey)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(25)),
        child: Column(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}