import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController()); 
    
    final userController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      // Menggunakan background putih kehijauan yang segar
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true,
        title: const Text(
          "Daftar Akun",
          style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)), 
          onPressed: () => Get.back()
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // --- BAGIAN AVATAR PICKER (Aesthetic Style) ---
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Stack(
                children: [
                  Obx(() => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: controller.selectedImagePath.value.isNotEmpty
                          ? FileImage(File(controller.selectedImagePath.value))
                          : null,
                      child: controller.selectedImagePath.value.isEmpty
                          ? const Icon(Icons.person_add_rounded, size: 50, color: Color(0xFF4CAF50))
                          : null,
                    ),
                  )),
                  Positioned(
                    bottom: 5, 
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32), 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Sentuh untuk pilih foto profil", 
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 40),

            // --- INPUT FIELDS (Matching Login Style) ---
            _buildTextField(
              controller: userController,
              label: "Username",
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: emailController,
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Obx(() => _buildTextField(
              controller: passController,
              label: "Password",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscureText: !controller.isPasswordVisible.value,
              suffixIcon: controller.isPasswordVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              onSuffixIconPressed: () => controller.isPasswordVisible.toggle(),
            )),
            const SizedBox(height: 40),

            // --- BUTTON SIGN UP (Gradient Style) ---
            Obx(() => Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: controller.isLoading.value ? null : () {
                  controller.register(
                    userController.text, 
                    emailController.text, 
                    passController.text
                  );
                },
                child: controller.isLoading.value 
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text(
                      "Daftar Sekarang", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
              ),
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget agar serasi dengan LoginPage
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: Colors.grey, size: 22),
                onPressed: onSuffixIconPressed,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}