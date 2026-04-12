import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_mobile/services/api_service.dart';
import 'package:projek_mobile/services/database_service.dart';
import 'package:projek_mobile/services/air_service.dart'; 
import '../controllers/dashboard_controller.dart';
import 'scan_page.dart';
import '../controllers/scan_controller.dart';
import 'alarm_page.dart'; 
// MapsPage sudah dihapus dari sini
import 'game_page.dart';
import 'notification_page.dart';

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

  // Fungsi navigasi ke halaman DAFTAR ALARM
  void _goToAlarmPage() {
    Get.to(() => const AlarmPage());
  }

  // HELPER UI: Kualitas Udara (LBS)
  Widget _buildAirCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AirService().getAirData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF6B8E23))),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(child: Text("Aktifkan lokasi (GPS) untuk cek udara 📍")),
          );
        }

        int aqi = snapshot.data!['list'][0]['main']['aqi'];
        
        List<String> status = ["", "Sangat Sehat 🌱", "Cukup Baik 👍", "Sedikit Polusi 😐", "Udara Buruk 😷", "Bahaya! ⚠️"];
        List<Color> colors = [Colors.grey, const Color(0xFF8DAA91), const Color(0xFF6B8E23), Colors.orange, Colors.redAccent, Colors.purple];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors[aqi].withOpacity(0.8), colors[aqi]],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors[aqi].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "Kualitas Udara Sekitarmu",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                status[aqi],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white70, size: 14),
                  SizedBox(width: 5),
                  Text(
                    "Berdasarkan Lokasi (LBS) 📍",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final dbService = Get.find<DatabaseService>();

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
                  
                  GestureDetector(
                    onTap: () {
                      dbService.markAllAsRead();
                      Get.to(() => const NotificationPage())?.then((_) {
                        setState(() {});
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 32,
                          color: Color(0xFF6B8E23),
                        ),
                        if (dbService.getUnreadCount() > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                "${dbService.getUnreadCount()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildAirCard(),

              const SizedBox(height: 30),

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

              const SizedBox(height: 15),

              Row(
                children: [
                  // Karena MapsPage dihapus, tombol Eco-Game kita buat Full Width 
                  // atau tetap setengah tapi tombol Maps-nya diganti Info Eco
                  Expanded(
                    child: _buildToolCard(
                      "Info Lingkungan",
                      Icons.info_outline_rounded,
                      Colors.green[50]!,
                      Colors.green,
                      () {
                        Get.snackbar("Eco Info", "Yuk, jaga bumi dengan tidak membuang sampah sembarangan!");
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildToolCard(
                      "Eco-Game",
                      Icons.sports_esports_rounded,
                      Colors.purple[50]!,
                      Colors.purple,
                      () => Get.to(() => const EcoGamePage()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}