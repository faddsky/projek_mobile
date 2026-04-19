import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart'; // Pastikan import ke controller baru

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ganti Get.find menjadi Get.put karena kita menggunakan controller baru khusus SignUp
    final controller = Get.put(SignUpController()); 
    
    final userController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), 
          onPressed: () => Get.back()
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // --- BAGIAN AVATAR PICKER ---
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Stack(
                children: [
                  Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: controller.selectedImagePath.value.isNotEmpty
                        ? FileImage(File(controller.selectedImagePath.value))
                        : null,
                    child: controller.selectedImagePath.value.isEmpty
                        ? const Icon(Icons.person_add_rounded, size: 50, color: Color(0xFF6B8E23))
                        : null,
                  )),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B8E23), 
                        shape: BoxShape.circle
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text("Pilih Foto Profil", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),

            // --- INPUT FIELDS ---
            TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: "Username",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => TextField(
              controller: passController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => controller.isPasswordVisible.toggle(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )),
            const SizedBox(height: 40),

            // --- BUTTON SIGN UP ---
            Obx(() => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8E23),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: controller.isLoading.value ? null : () {
                  // Kirim data ke register() di SignUpController
                  // Validasi email sudah ada di dalam fungsi register tersebut
                  controller.register(
                    userController.text, 
                    emailController.text, 
                    passController.text
                  );
                },
                child: controller.isLoading.value 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Daftar Sekarang", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}