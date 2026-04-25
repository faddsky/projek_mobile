import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/home_controller.dart';
import '../controllers/scan_controller.dart';
import 'scan_page.dart';
import 'alarm_page.dart';
import 'game_page.dart';
import 'notification_page.dart';
import 'conversion_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _currentIndex = 0;
  late HomeController controller;
  late DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    dbService = Get.find<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    final sessionBox = Hive.box(DatabaseService.sessionBox);
    final String currentUserId = sessionBox.get('currentUser', defaultValue: '').toString();
    final Map? userData = Hive.box(DatabaseService.authBox).get('user_$currentUserId');
    final String username = userData?['username'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMainDashboard(controller, username, dbService),
          const ConversionPage(),
          const FeedbackPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF2E7D32), // Emerald Bold
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Beranda"),
            BottomNavigationBarItem(icon: Icon(Icons.currency_exchange_rounded), label: "Konversi"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Saran"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDashboard(HomeController controller, String name, DatabaseService db) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(controller, name, db),
            const SizedBox(height: 30),
            Obx(() => _buildAirCard(controller)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Eco AI Tools ✨",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green[900]),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildToolGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HomeController controller, String name, DatabaseService db) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.getGreeting(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            Text(
              "$name",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20)),
            ),
          ],
        ),
        _buildNotificationBadge(db),
      ],
    );
  }

  Widget _buildAirCard(HomeController controller) {
    if (controller.isLoading.value) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }
    if (controller.hasError.value) return _buildErrorState();

    final airData = controller.airData.value;
    if (airData == null) return _buildErrorState();

    int aqi = airData['list'][0]['main']['aqi'];
    List<Color> colors = [
      Colors.grey,
      const Color(0xFF4CAF50), // Sehat
      const Color(0xFF8BC34A), // Baik
      const Color(0xFFFFB300), // Sedikit Polusi
      const Color(0xFFFF7043), // Buruk
      const Color(0xFFD32F2F), // Bahaya
    ];
    List<String> status = ["", "Sangat Sehat 🌱", "Cukup Baik 👍", "Sedikit Polusi 😐", "Udara Buruk 😷", "Bahaya! ⚠️"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[aqi], colors[aqi].withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: colors[aqi].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.wb_sunny_rounded, size: 100, color: Colors.white.withOpacity(0.2)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Kualitas Udara Sekitarmu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Text(status[aqi], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(controller.locationName.value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.orange.shade100)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          const Text("Gagal memuat data udara 📍", style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(DatabaseService db) {
    return GestureDetector(
      onTap: () {
        db.markAllAsRead();
        Get.to(() => const NotificationPage());
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 28, color: Color(0xFF2E7D32)),
            Obx(() {
              int count = db.unreadCount.value;
              if (count > 0) {
                return Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToolGrid() {
    return Column(
      children: [
        _buildToolCard(
          "Scan Sampah",
          Icons.document_scanner_rounded,
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          () => Get.to(() => const ScanPage(), binding: BindingsBuilder(() => Get.put(ScanController()))),
          isFullWidth: true,
          subtitle: "Identifikasi jenis sampah dengan AI",
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildToolCard("Jadwal", Icons.alarm_on_rounded, const Color(0xFFE3F2FD), Colors.blue[700]!, () => Get.to(() => const AlarmPage()))),
            const SizedBox(width: 15),
            Expanded(child: _buildToolCard("Eco-Game", Icons.sports_esports_rounded, const Color(0xFFF3E5F5), Colors.purple[700]!, () => Get.to(() => const GamePage()))),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(String t, IconData i, Color b, Color ic, VoidCallback o, {bool isFullWidth = false, String? subtitle}) {
    return InkWell(
      onTap: o,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: ic.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Icon(i, size: isFullWidth ? 45 : 35, color: ic),
            const SizedBox(height: 10),
            Text(t, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ic.withOpacity(0.8))),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: ic.withOpacity(0.6))),
            ]
          ],
        ),
      ),
    );
  }
}