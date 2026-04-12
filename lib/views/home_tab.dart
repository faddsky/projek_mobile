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
// Import halaman untuk navigasi navbar
import 'conversion_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Variabel untuk melacak index halaman yang aktif
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final dbService = Get.find<DatabaseService>();

    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String username = Hive.box(DatabaseService.authBox)
        .get('user_${sessionBox.get('currentUser')}')?['username'] ?? 'User';

    // Daftar halaman yang dihubungkan ke navbar
    final List<Widget> _pages = [
      _buildMainDashboard(controller, username, dbService), // Index 0: Tampilan Utama
      const ConversionPage(),                               // Index 1: Konversi
      const FeedbackPage(),                                 // Index 2: Saran
      const ProfilePage(),                                  // Index 3: Profil
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      // Menampilkan widget berdasarkan index yang dipilih
      body: _pages[_currentIndex],
      
      // Bottom Navigation Bar yang dikembalikan fungsinya
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF6B8E23),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.currency_exchange), label: "Konversi"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Saran"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  // Widget untuk isi konten utama Dashboard (sebelumnya ada di body Scaffold)
  Widget _buildMainDashboard(HomeController controller, String name, DatabaseService db) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(controller, name, db),
            const SizedBox(height: 25),
            
            // Kartu Udara
            Obx(() => _buildAirCard(controller)),
            const SizedBox(height: 25),

            const Text("Eco AI Tools", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Grid Menu
            _buildToolGrid(),
          ],
        ),
      ),
    );
  }

  // --- Widget Header ---
  Widget _buildHeader(HomeController controller, String name, DatabaseService db) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(controller.getGreeting(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text("$name ✨", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green[900])),
        ]),
        _buildNotificationBadge(db),
      ],
    );
  }

  // --- Widget Kualitas Udara ---
  Widget _buildAirCard(HomeController controller) {
    if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
    if (controller.hasError.value) return _buildErrorState();

    int aqi = controller.airData.value!['list'][0]['main']['aqi'];
    List<Color> colors = [Colors.grey, const Color(0xFF8DAA91), const Color(0xFF6B8E23), Colors.orange, Colors.redAccent, Colors.purple];
    List<String> status = ["", "Sangat Sehat 🌱", "Cukup Baik 👍", "Sedikit Polusi 😐", "Udara Buruk 😷", "Bahaya! ⚠️"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors[aqi].withOpacity(0.8), colors[aqi]]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: colors[aqi].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: [
        const Text("Kualitas Udara Sekitarmu", style: TextStyle(color: Colors.white)),
        Text(status[aqi], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on, color: Colors.white70, size: 14),
          Text(controller.locationName.value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildErrorState() => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(20), 
    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(30)), 
    child: const Text("Gagal memuat data udara 📍", textAlign: TextAlign.center)
  );

  Widget _buildNotificationBadge(DatabaseService db) => GestureDetector(
    onTap: () => Get.to(() => const NotificationPage()),
    child: Stack(clipBehavior: Clip.none, children: [
      const Icon(Icons.notifications_none_rounded, size: 32, color: Color(0xFF6B8E23)),
      if (db.getUnreadCount() > 0) 
        Positioned(
          right: -2, 
          top: -2, 
          child: Container(
            padding: const EdgeInsets.all(4), 
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), 
            child: Text("${db.getUnreadCount()}", style: const TextStyle(color: Colors.white, fontSize: 10))
          )
        ),
    ]),
  );

  // --- Widget Menu Grid ---
  Widget _buildToolGrid() => Column(
    children: [
      _buildToolCard(
        "Scan Sampah", 
        Icons.camera_enhance_rounded, 
        Colors.orange[50]!, 
        Colors.orange, 
        () => Get.to(() => const ScanPage(), binding: BindingsBuilder(() => Get.put(ScanController()))),
        isFullWidth: true
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _buildToolCard(
              "Jadwal Sampah", 
              Icons.alarm_on_rounded, 
              Colors.blue[50]!, 
              Colors.blue, 
              () => Get.to(() => const AlarmPage())
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildToolCard(
              "Eco-Game", 
              Icons.sports_esports_rounded, 
              Colors.purple[50]!, 
              Colors.purple, 
              () => Get.to(() => const GamePage())
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildToolCard(String t, IconData i, Color b, Color ic, VoidCallback o, {bool isFullWidth = false}) => InkWell(
    onTap: o, 
    borderRadius: BorderRadius.circular(25),
    child: Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(25)), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 40, color: ic), 
          const SizedBox(height: 10), 
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
        ]
      )
    )
  );
}