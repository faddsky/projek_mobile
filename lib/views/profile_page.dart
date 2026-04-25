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
  
  // Palet Warna Emerald Aesthetic
  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF388E3C);
  final Color sageLight = const Color(0xFFE8F5E9);
  final Color backgroundLight = const Color(0xFFF8FAF8);

  var hapusBiometrik = false.obs;

  // --- LOGIC: AMBIL FOTO ---
  Future<void> _pickImage(ImageSource source, Box authBox, String currentUser, dynamic userData) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      var newData = Map<String, dynamic>.from(userData);
      newData['profilePic'] = pickedFile.path;
      await authBox.put('user_$currentUser', newData);
      setState(() {}); // Refresh UI
      Get.back();
      Get.snackbar("Sukses", "Foto profil diperbarui! ✨", 
          backgroundColor: Colors.white, colorText: primaryGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Get.put(LoginController());
    final dbService = Get.find<DatabaseService>();

    var sessionBox = Hive.box(DatabaseService.sessionBox);
    String currentUser = sessionBox.get('currentUser') ?? "";
    var authBox = Hive.box(DatabaseService.authBox);
    var userData = authBox.get('user_$currentUser');

    String namaUser = userData?['username'] ?? 'User';
    String emailUser = userData?['email'] ?? 'user@ecostep.com';
    String? fotoPath = userData?['profilePic'];

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildProfileHeader(fotoPath, namaUser, emailUser, authBox, currentUser, userData),
            const SizedBox(height: 40),
            
            // MENU CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.person_outline_rounded,
                      title: "Detail Profil",
                      subtitle: "Kelola username dan email",
                      onTap: () => _showEditDialog(authBox, currentUser, userData),
                    ),
                    const Divider(height: 1, indent: 70, endIndent: 20),
                    _buildMenuTile(
                      icon: Icons.lock_open_rounded,
                      title: "Ubah Kata Sandi",
                      subtitle: "Ganti password akun kamu",
                      onTap: () => _showChangePasswordDialog(authBox, currentUser, userData, dbService),
                    ),
                    const Divider(height: 1, indent: 70, endIndent: 20),
                    _buildMenuTile(
                      icon: Icons.power_settings_new_rounded,
                      title: "Keluar Aplikasi",
                      subtitle: "Sesi aktif: $namaUser",
                      isLogout: true,
                      onTap: () => _showLogoutDialog(loginController),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- HEADER PROFIL (FIXED PHOTO) ---
  Widget _buildProfileHeader(String? path, String name, String email, Box box, String userKey, dynamic data) {
    ImageProvider profileImage;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      profileImage = FileImage(File(path));
    } else {
      profileImage = NetworkImage('https://ui-avatars.com/api/?name=$name&background=E8F5E9&color=1B5E20');
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [BoxShadow(color: primaryGreen.withAlpha(20), blurRadius: 20)],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: sageLight,
                backgroundImage: profileImage,
              ),
            ),
            GestureDetector(
              onTap: () => _showPickerOptions(box, userKey, data),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: Colors.white, width: 3)
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryGreen)),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isLogout ? Colors.red[50] : sageLight, borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: isLogout ? Colors.red : primaryGreen, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLogout ? Colors.red : Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
    );
  }

  // --- REUSABLE DIALOG BASE (Style Biometrik) ---
  Widget _buildBaseDialog({required String title, required Widget content, required VoidCallback onConfirm, bool isDanger = false}) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDanger ? Colors.redAccent : primaryGreen)),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDanger ? Colors.redAccent : accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: onConfirm,
                child: Text(isDanger ? "Ya, Keluar" : "Simpan Perubahan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField({required TextEditingController controller, required String label, required IconData icon, bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: backgroundLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  // --- DIALOG DETAIL PROFIL ---
  void _showEditDialog(Box authBox, String usernameKey, dynamic oldData) {
    final nameCtrl = TextEditingController(text: oldData['username']);
    final emailCtrl = TextEditingController(text: oldData['email']);
    Get.dialog(_buildBaseDialog(
      title: "Edit Profil",
      content: Column(children: [
        _buildDialogField(controller: nameCtrl, label: "Username", icon: Icons.person_outline),
        const SizedBox(height: 15),
        _buildDialogField(controller: emailCtrl, label: "Email", icon: Icons.mail_outline),
      ]),
      onConfirm: () async {
        var newData = Map<String, dynamic>.from(oldData);
        newData['username'] = nameCtrl.text;
        newData['email'] = emailCtrl.text;
        await authBox.put('user_$usernameKey', newData);
        setState(() {});
        Get.back();
      },
    ));
  }

  // --- DIALOG UBAH KATA SANDI (FIXED DENGAN KONFIRMASI) ---
  void _showChangePasswordDialog(Box authBox, String usernameKey, dynamic oldData, DatabaseService dbService) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    Get.dialog(_buildBaseDialog(
      title: "Ubah Sandi",
      content: Column(children: [
        _buildDialogField(controller: oldPass, label: "Sandi Lama", icon: Icons.lock_open, isPass: true),
        const SizedBox(height: 15),
        _buildDialogField(controller: newPass, label: "Sandi Baru", icon: Icons.lock_outline, isPass: true),
        const SizedBox(height: 15),
        _buildDialogField(controller: confirmPass, label: "Konfirmasi Sandi Baru", icon: Icons.lock_reset, isPass: true),
      ]),
      onConfirm: () {
        if (dbService.hashPassword(oldPass.text) != oldData['password']) {
          Get.snackbar("Error", "Sandi lama salah!");
          return;
        }
        if (newPass.text != confirmPass.text) {
          Get.snackbar("Error", "Konfirmasi sandi tidak cocok!");
          return;
        }
        var newData = Map<String, dynamic>.from(oldData);
        newData['password'] = dbService.hashPassword(newPass.text);
        authBox.put('user_$usernameKey', newData);
        Get.back();
        Get.snackbar("Sukses", "Sandi berhasil diperbarui!");
      },
    ));
  }

  // --- DIALOG KELUAR ---
  void _showLogoutDialog(LoginController controller) {
    hapusBiometrik.value = false;
    Get.dialog(_buildBaseDialog(
      title: "Konfirmasi Keluar",
      isDanger: true,
      content: Column(children: [
        const Text("Apakah kamu yakin ingin keluar?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 15),
        Obx(() => CheckboxListTile(
          title: const Text("Hapus data biometrik", style: TextStyle(fontSize: 12)),
          value: hapusBiometrik.value,
          onChanged: (val) => hapusBiometrik.value = val!,
          activeColor: Colors.redAccent,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        )),
      ]),
      onConfirm: () => controller.logout(hapusBiometrik.value),
    ));
  }

  void _showPickerOptions(Box authBox, String currentUser, dynamic userData) {
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 25),
        const Text("Ganti Foto Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildPickerBtn(Icons.camera_alt_rounded, "Kamera", () => _pickImage(ImageSource.camera, authBox, currentUser, userData)),
          _buildPickerBtn(Icons.image_rounded, "Galeri", () => _pickImage(ImageSource.gallery, authBox, currentUser, userData)),
        ]),
      ]),
    ));
  }

  Widget _buildPickerBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: sageLight, shape: BoxShape.circle), child: Icon(icon, color: primaryGreen, size: 30)),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]));
  }
}