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

    // 2. Validasi Format Email (Wajib ada @ dan domain)
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

      Get.snackbar(
        "Berhasil", 
        "Akun $cleanUsername berhasil dibuat!", 
        backgroundColor: Colors.green, 
        colorText: Colors.white
      );
      
      // Reset path gambar setelah sukses
      selectedImagePath.value = ''; 
      
      // Tunggu sebentar lalu balik ke Login
      Future.delayed(const Duration(milliseconds: 1500), () => Get.back()); 
      
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
      snackPosition: SnackPosition.BOTTOM
    );
  }
}