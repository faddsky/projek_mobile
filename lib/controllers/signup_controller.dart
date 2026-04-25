import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';

class SignUpController extends GetxController {
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;
  var selectedImagePath = ''.obs;

  // Fungsi Hash Password agar aman di database
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Ambil Foto Profil dari Galeri
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      selectedImagePath.value = pickedFile.path;
    }
  }

  void register(String username, String email, String password) async {
    // 1. Validasi Input Kosong
    if (username.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      _showError("Harap isi semua field!");
      return;
    }

    // 2. Validasi Format Email
    if (!GetUtils.isEmail(email.trim())) {
      _showError("Format email tidak valid! Gunakan @gmail.com atau lainnya.");
      return;
    }

    isLoading.value = true;
    try {
      var box = Hive.box(DatabaseService.authBox);
      String cleanUsername = username.trim();
      String cleanEmail = email.trim().toLowerCase();

      // 3. Validasi Username Terdaftar
      if (box.containsKey('user_$cleanUsername')) {
        _showError("Username '$cleanUsername' sudah terdaftar!");
        isLoading.value = false;
        return;
      }

      // 4. Validasi Email Terdaftar (Cek manual di Hive)
      var allUsers = box.values.toList();
      bool isEmailExist = allUsers.any((user) {
        if (user is Map) {
          return user['email'].toString().toLowerCase() == cleanEmail;
        }
        return false;
      });

      if (isEmailExist) {
        _showError("Email '$cleanEmail' sudah digunakan!");
        isLoading.value = false;
        return;
      }

      // 5. Simpan ke Hive
      await box.put('user_$cleanUsername', {
        'username': cleanUsername,
        'email': cleanEmail,
        'password': hashPassword(password),
        'profilePic': selectedImagePath.value,
      });

      // --- BAGIAN NOTIFIKASI BERHASIL & REDIRECT ---
      Get.snackbar(
        "Pendaftaran Berhasil", 
        "Akun $cleanUsername berhasil dibuat!", 
        backgroundColor: const Color(0xFF2E7D32), // Hijau sesuai tema EcoStep
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(15),
        borderRadius: 15,
      );
      
      // Reset path gambar setelah sukses
      selectedImagePath.value = ''; 
      
      // Tunggu 2 detik (sesuai durasi snackbar) lalu balik ke Login
      Future.delayed(const Duration(seconds: 2), () {
        Get.back(); // Kembali ke halaman Login
      }); 
      
    } catch (e) {
      _showError("Gagal mendaftar: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      "Peringatan", 
      message, 
      backgroundColor: Colors.orangeAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      borderRadius: 15,
    );
  }
}