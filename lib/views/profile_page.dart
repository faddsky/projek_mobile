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
      Get.snackbar("Sukses", "Foto profil berhasil diperbarui! ✨",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showPickerOptions(Box authBox, String currentUser, dynamic userData) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ganti Foto Profil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6B8E23)),
              title: const Text("Kamera"),
              onTap: () =>
                  _pickImage(ImageSource.camera, authBox, currentUser, userData),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6B8E23)),
              title: const Text("Galeri Foto"),
              onTap: () =>
                  _pickImage(ImageSource.gallery, authBox, currentUser, userData),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());
    final dbService = Get.find<DatabaseService>();

    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String? currentUser = sessionBox.get('currentUser');

    var authBox = Hive.box(DatabaseService.authBox);
    var userData = authBox.get('user_$currentUser');

    String namaUser = userData?['username'] ?? 'User';
    String emailUser = userData?['email'] ?? 'email@gmail.com';
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
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFF8DAA91),
                        backgroundImage: (fotoPath != null &&
                                fotoPath.isNotEmpty)
                            ? FileImage(File(fotoPath)) as ImageProvider
                            : NetworkImage(
                                'https://ui-avatars.com/api/?name=$namaUser&background=8DAA91&color=fff'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            _showPickerOptions(authBox, currentUser!, userData),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Color(0xFF6B8E23), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(namaUser,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              Text(emailUser,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),

              const SizedBox(height: 35),

              // --- Menu ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.badge_outlined,
                      title: "Detail Profil",
                      subtitle: "Kelola username dan email",
                      onTap: () =>
                          _showEditDialog(authBox, currentUser!, userData),
                    ),
                    const SizedBox(height: 15),
                    _buildMenuTile(
                      icon: Icons.lock_reset_rounded,
                      title: "Ubah Kata Sandi",
                      subtitle: "Ganti password akun kamu",
                      onTap: () => _showChangePasswordDialog(
                          authBox, currentUser!, userData, dbService),
                    ),
                    const SizedBox(height: 15),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading:
          Icon(icon, color: isLogout ? Colors.red : const Color(0xFF6B8E23)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLogout ? Colors.red : Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  void _showEditDialog(Box authBox, String usernameKey, dynamic oldData) {
    final nameCtrl = TextEditingController(text: oldData['username']);
    final emailCtrl = TextEditingController(text: oldData['email']);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Profil ✨",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4D2E))),
              const SizedBox(height: 25),
              _buildTextField(
                  controller: nameCtrl, label: "Username", icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: emailCtrl, label: "Email", icon: Icons.mail_outline),
              const SizedBox(height: 25),
              _buildActionButtons(
                onConfirm: () async {
                  String newUsername = nameCtrl.text.trim();
                  String newEmail = emailCtrl.text.trim();

                  if (newUsername.isEmpty || newEmail.isEmpty) {
                    Get.snackbar("Error", "Username dan Email tidak boleh kosong");
                    return;
                  }

                  var newData = Map<String, dynamic>.from(oldData);
                  newData['username'] = newUsername;
                  newData['email'] = newEmail;

                  if (newUsername != usernameKey) {
                    // 1. Simpan data ke Key baru (user_dilaa)
                    await authBox.put('user_$newUsername', newData);
                    // 2. Hapus data di Key lama (user_dila)
                    await authBox.delete('user_$usernameKey');
                    // 3. Update session_box agar aplikasi tahu user aktif sudah berubah kuncinya
                    var sessionBox = Hive.box(DatabaseService.sessionBox);
                    await sessionBox.put('currentUser', newUsername);
                  } else {
                    // Jika username tetap, cukup update data di Key yang sama
                    await authBox.put('user_$usernameKey', newData);
                  }

                  setState(() {});
                  Get.back();
                  Get.snackbar("Sukses", "Profil berhasil diperbarui! ✨");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(Box authBox, String usernameKey, dynamic oldData,
      DatabaseService dbService) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ubah Kata Sandi 🔐",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E4D2E))),
                const SizedBox(height: 25),
                _buildTextField(
                    controller: oldPassCtrl,
                    label: "Kata Sandi Lama",
                    icon: Icons.lock_open_rounded,
                    isPassword: true),
                const SizedBox(height: 15),
                _buildTextField(
                    controller: newPassCtrl,
                    label: "Kata Sandi Baru",
                    icon: Icons.lock_outline,
                    isPassword: true),
                const SizedBox(height: 15),
                _buildTextField(
                    controller: confirmPassCtrl,
                    label: "Konfirmasi Sandi Baru",
                    icon: Icons.lock_reset,
                    isPassword: true),
                const SizedBox(height: 25),
                _buildActionButtons(
                  onConfirm: () {
                    String oldPassHashed =
                        dbService.hashPassword(oldPassCtrl.text);
                    if (oldPassHashed != oldData['password']) {
                      Get.snackbar("Error", "Kata sandi lama salah! ❌",
                          backgroundColor: Colors.white);
                      return;
                    }

                    if (newPassCtrl.text.isEmpty) {
                      Get.snackbar("Error", "Sandi baru tidak boleh kosong!");
                      return;
                    }

                    if (newPassCtrl.text == confirmPassCtrl.text) {
                      var newData = Map<String, dynamic>.from(oldData);
                      newData['password'] =
                          dbService.hashPassword(newPassCtrl.text);
                      authBox.put('user_$usernameKey', newData);
                      Get.back();
                      Get.snackbar("Sukses", "Kata sandi berhasil diperbarui! 🔐");
                    } else {
                      Get.snackbar(
                          "Error", "Sandi baru dan konfirmasi tidak cocok!",
                          backgroundColor: Colors.white);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F5F1),
        prefixIcon: Icon(icon, color: const Color(0xFF6B8E23)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButtons({required VoidCallback onConfirm}) {
    return Row(
      children: [
        Expanded(
            child: TextButton(
                onPressed: () => Get.back(),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)))),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E23),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: onConfirm,
            child: const Text("Simpan",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(LoginController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Logout",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4D2E))),
              const SizedBox(height: 15),
              const Text("Yakin ingin keluar?",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              _buildActionButtonsLogout(onConfirm: () => controller.logout()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsLogout({required VoidCallback onConfirm}) {
    return Row(
      children: [
        Expanded(
            child: TextButton(
                onPressed: () => Get.back(),
                child: const Text("Tidak", style: TextStyle(color: Colors.grey)))),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: onConfirm,
            child: const Text("Ya",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}