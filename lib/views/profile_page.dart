import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:projek_mobile/services/api_service.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/login_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());

    // 1. Ambil session user yang sedang aktif
    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String? currentUser = sessionBox.get('currentUser'); 

    // 2. Ambil data lengkap dari auth_box berdasarkan username fadilah
    var authBox = Hive.box(DatabaseService.authBox);
    var userData = authBox.get('user_$currentUser');

    // 3. Ekstrak data (Username, Email, dan Foto)
    String namaUser = userData?['username'] ?? 'Fadilah';
    String emailUser = userData?['email'] ?? 'cikin@gmail.com';
    String? fotoPath = userData?['profilePic']; 

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              // --- Bagian Foto Profil ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFF8DAA91),
                        // Logika: Jika ada path foto di DB pakai File, jika tidak pakai Inisial
                        backgroundImage: (fotoPath != null && fotoPath.isNotEmpty)
                            ? FileImage(File(fotoPath)) as ImageProvider
                            : NetworkImage('https://ui-avatars.com/api/?name=$namaUser&background=8DAA91&color=fff'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF6B8E23), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Identitas dari Database ---
              Text(namaUser, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text(emailUser, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),

              // --- Statistik dari Google Cloud ---
              _buildCloudStats(),
              const SizedBox(height: 35),

              // --- Menu Detail & Edit ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.badge_outlined,
                      title: "Detail Profil",
                      subtitle: "Kelola username dan email",
                      onTap: () => _showEditDialog(authBox, currentUser!, userData),
                    ),
                    const SizedBox(height: 15),
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: "Keluar Aplikasi",
                      subtitle: "Sesi: $namaUser",
                      isLogout: true,
                      onTap: () => _showLogoutDialog(loginController),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi ambil data dari GCP
  Widget _buildCloudStats() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchData(),
      builder: (context, snapshot) {
        int totalLangkah = 0;
        if (snapshot.hasData) {
          for (var item in snapshot.data!) {
            totalLangkah += (item['langkah'] as int? ?? 0);
          }
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statBox("Poin Eco", "${(totalLangkah / 10).floor()}"),
            const SizedBox(width: 50),
            _statBox("Total Langkah", "$totalLangkah"),
          ],
        );
      },
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6B8E23))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Icon(icon, color: isLogout ? Colors.red : const Color(0xFF6B8E23)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isLogout ? Colors.red : Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  // --- DIALOG EDIT PROFIL (UPDATE AUTH_BOX) ---
  void _showEditDialog(Box authBox, String usernameKey, dynamic oldData) {
    final nameCtrl = TextEditingController(text: oldData['username']);
    final emailCtrl = TextEditingController(text: oldData['email']);

    Get.defaultDialog(
      title: "Edit Detail",
      content: Column(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Username")),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
        ],
      ),
      textConfirm: "Simpan",
      onConfirm: () {
        // Update map data di auth_box
        var newData = Map<String, dynamic>.from(oldData);
        newData['username'] = nameCtrl.text;
        newData['email'] = emailCtrl.text;
        
        authBox.put('user_$usernameKey', newData);
        
        setState(() {}); // Refresh UI layar profil
        Get.back();
        Get.snackbar("Berhasil", "Data di database terupdate! ✅");
      },
    );
  }

  void _showLogoutDialog(LoginController controller) {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Yakin ingin keluar?",
      textConfirm: "Ya",
      buttonColor: Colors.redAccent,
      onConfirm: () => controller.logout(),
    );
  }
}