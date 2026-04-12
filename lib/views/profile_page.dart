import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/login_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  
  // Warna Tema Utama
  final Color primaryGreen = const Color(0xFF6B8E23);
  final Color softGreen = const Color(0xFF8DAA91);
  final Color backgroundLight = const Color(0xFFF1F5F1);

  // --- LOGIC: PICK IMAGE ---
  Future<void> _pickImage(
    ImageSource source,
    Box authBox,
    String currentUser,
    dynamic userData,
  ) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      var newData = Map<String, dynamic>.from(userData);
      newData['profilePic'] = pickedFile.path;
      await authBox.put('user_$currentUser', newData);
      setState(() {});
      Get.back();
      Get.snackbar(
        "Sukses", 
        "Foto profil berhasil diperbarui! ✨",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Get.put(LoginController());
    final dbService = Get.find<DatabaseService>();

    // Ambil Data dari Hive
    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String currentUser = sessionBox.get('currentUser') ?? "";
    var authBox = Hive.box(DatabaseService.authBox);
    var userData = authBox.get('user_$currentUser');

    String namaUser = userData?['username'] ?? 'User';
    String emailUser = userData?['email'] ?? 'email@gmail.com';
    String? fotoPath = userData?['profilePic'];

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              // --- HEADER: FOTO PROFIL ---
              _buildProfileHeader(fotoPath, namaUser, emailUser, authBox, currentUser, userData),
              
              const SizedBox(height: 40),

              // --- MENU SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        icon: Icons.badge_outlined,
                        title: "Detail Profil",
                        subtitle: "Kelola username dan email",
                        onTap: () => _showEditDialog(authBox, currentUser, userData),
                      ),
                      const Divider(height: 1, indent: 70),
                      _buildMenuTile(
                        icon: Icons.lock_reset_rounded,
                        title: "Ubah Kata Sandi",
                        subtitle: "Ganti password akun kamu",
                        onTap: () => _showChangePasswordDialog(authBox, currentUser, userData, dbService),
                      ),
                      const Divider(height: 1, indent: 70),
                      _buildMenuTile(
                        icon: Icons.logout_rounded,
                        title: "Keluar Aplikasi",
                        subtitle: "Sesi aktif: $namaUser",
                        isLogout: true,
                        onTap: () => _showLogoutDialog(loginController),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Header Profil
  Widget _buildProfileHeader(String? path, String name, String email, Box box, String userKey, dynamic data) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: softGreen,
                  backgroundImage: (path != null && path.isNotEmpty)
                      ? FileImage(File(path)) as ImageProvider
                      : NetworkImage('https://ui-avatars.com/api/?name=$name&background=8DAA91&color=fff'),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showPickerOptions(box, userKey, data),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGreen, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // Widget Baris Menu
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withOpacity(0.1) : primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isLogout ? Colors.red : primaryGreen),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isLogout ? Colors.red : Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  // --- BOTTOM SHEET: PICKER ---
  void _showPickerOptions(Box authBox, String currentUser, dynamic userData) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ganti Foto Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primaryGreen),
              title: const Text("Kamera"),
              onTap: () => _pickImage(ImageSource.camera, authBox, currentUser, userData),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryGreen),
              title: const Text("Galeri Foto"),
              onTap: () => _pickImage(ImageSource.gallery, authBox, currentUser, userData),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG: EDIT PROFIL ---
  void _showEditDialog(Box authBox, String usernameKey, dynamic oldData) {
    final nameCtrl = TextEditingController(text: oldData['username']);
    final emailCtrl = TextEditingController(text: oldData['email']);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Edit Profil ✨", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
              const SizedBox(height: 25),
              _buildTextField(controller: nameCtrl, label: "Username", icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(controller: emailCtrl, label: "Email", icon: Icons.mail_outline),
              const SizedBox(height: 25),
              _buildActionButtons(
                onConfirm: () async {
                  String newName = nameCtrl.text.trim();
                  String newEmail = emailCtrl.text.trim();

                  if (newName.isEmpty || newEmail.isEmpty) return;

                  var newData = Map<String, dynamic>.from(oldData);
                  newData['username'] = newName;
                  newData['email'] = newEmail;

                  if (newName != usernameKey) {
                    await authBox.put('user_$newName', newData);
                    await authBox.delete('user_$usernameKey');
                    var sessionBox = Hive.box(DatabaseService.sessionBox);
                    await sessionBox.put('currentUser', newName);
                  } else {
                    await authBox.put('user_$usernameKey', newData);
                  }

                  setState(() {});
                  Get.back();
                  Get.snackbar("Sukses", "Profil diperbarui!");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOG: CHANGE PASSWORD ---
  void _showChangePasswordDialog(Box authBox, String usernameKey, dynamic oldData, DatabaseService dbService) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ubah Sandi 🔐", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
              const SizedBox(height: 25),
              _buildTextField(controller: oldPassCtrl, label: "Sandi Lama", icon: Icons.lock_open, isPassword: true),
              const SizedBox(height: 15),
              _buildTextField(controller: newPassCtrl, label: "Sandi Baru", icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 15),
              _buildTextField(controller: confirmPassCtrl, label: "Konfirmasi", icon: Icons.lock_reset, isPassword: true),
              const SizedBox(height: 25),
              _buildActionButtons(
                onConfirm: () {
                  if (dbService.hashPassword(oldPassCtrl.text) != oldData['password']) {
                    Get.snackbar("Error", "Sandi lama salah!");
                    return;
                  }
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    Get.snackbar("Error", "Sandi tidak cocok!");
                    return;
                  }
                  var newData = Map<String, dynamic>.from(oldData);
                  newData['password'] = dbService.hashPassword(newPassCtrl.text);
                  authBox.put('user_$usernameKey', newData);
                  Get.back();
                  Get.snackbar("Sukses", "Sandi diperbarui!");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: backgroundLight,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButtons({required VoidCallback onConfirm}) {
    return Row(
      children: [
        Expanded(child: TextButton(onPressed: () => Get.back(), child: const Text("Batal", style: TextStyle(color: Colors.grey)))),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: onConfirm,
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(LoginController controller) {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Yakin ingin keluar?",
      textConfirm: "Ya",
      textCancel: "Tidak",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () => controller.logout(),
    );
  }
}