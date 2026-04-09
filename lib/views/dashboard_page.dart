import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projek_mobile/services/api_service.dart';
import 'home_tab.dart';
import 'conversion_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Variabel reaktif untuk mengatur index menu
    var currentIndex = 0.obs;

    // List halaman yang akan tampil di dashboard
    final List<Widget> menuPages = [
      const HomeTab(), // Isi konten utama (Langkah kaki, AI Scanner)
      const ConversionPage(), // Halaman Konversi (Mata Uang & Waktu)
      const FeedbackPage(), // Menu Kesan & Saran
      const ProfilePage(), // Menu Profil & Logout
    ];

    return Scaffold(
      body: Obx(() => menuPages[currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: currentIndex.value,
          onTap: (index) => currentIndex.value = index,
          selectedItemColor: const Color(0xFF6B8E23), // Warna hijau sage/army
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.currency_exchange), label: "Konversi"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Saran"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
          ],
        ),
      ),
    );
  }
}