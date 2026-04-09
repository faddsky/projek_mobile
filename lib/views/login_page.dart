import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import 'signup_page.dart'; // Import halaman signup

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final userController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Logo/Icon Aesthetic
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, size: 80, color: Color(0xFF6B8E23)),
              ),
              const SizedBox(height: 20),
              Text("Welcome Back!", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green[900])),
              const Text("EcoStep: Green Lifestyle Partner", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),
              
              // Field Username
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Field Password
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                  ),
                ),
              )),
              
              const SizedBox(height: 30),
              
              // Button Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8E23),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  onPressed: () => controller.login(userController.text, passController.text),
                  child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Button Biometric
              IconButton(
                icon: const Icon(Icons.fingerprint, size: 60, color: Color(0xFF6B8E23)),
                onPressed: () => controller.loginWithBiometric(),
              ),
              const Text("Use Biometric", style: TextStyle(fontSize: 12, color: Colors.grey)),
              
              const SizedBox(height: 40),
              
              // Navigasi ke Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Get.to(() => const SignUpPage()),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Color(0xFF6B8E23), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}