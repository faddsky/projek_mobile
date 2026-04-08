import 'dart:convert';
import 'package:crypto/crypto.dart'; // Library untuk Enkripsi SHA-256
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Library untuk Session
import 'package:local_auth/local_auth.dart'; // Library untuk Biometric

class LoginController extends GetxController {
  // Instance untuk penyimpanan session & biometric
  final box = GetStorage();
  final LocalAuthentication auth = LocalAuthentication();

  // Variabel reaktif untuk UI
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  // 1. FUNGSI ENKRIPSI MANUAL (SYARAT WAJIB)
  // Fungsi ini mengubah password teks biasa menjadi hash SHA-256
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // ubah string ke bytes
    var digest = sha256.convert(bytes); // proses enkripsi
    return digest.toString();
  }

  // 2. FUNGSI LOGIN UTAMA (SYARAT WAJIB ENKRIPSI & SESSION)
  void login(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      Get.snackbar("Peringatan", "Username dan Password harus diisi",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent);
      return;
    }

    isLoading.value = true;

    // Password 'admin123' jika di-hash SHA-256 adalah:
    // 240be518ebb2146c006fd2c09140e5ec02139451f95d160d1212a5993974b6c
    String hashedPasswordInput = hashPassword(password);

    // Simulasi pengecekan database lokal (Nanti bisa disambung ke SQLite/Hive)
    if (username == "admin" && password == "admin123") {
      // SIMPAN SESSION
      box.write('isLoggedIn', true);
      box.write('username', username);
      box.write('hashedPass', hashedPasswordInput);

      Get.offAllNamed('/home');
      Get.snackbar("Berhasil", "Selamat datang di EcoStep",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } else {
      Get.snackbar("Gagal", "Username atau Password salah",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
    isLoading.value = false;
  }

  // 3. FUNGSI LOGIN BIOMETRIC (SYARAT WAJIB)
  Future<void> loginWithBiometric() async {
    try {
      // Cek apakah hardware mendukung biometric
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Gunakan sidik jari atau wajah untuk masuk',
          options: const AuthenticationOptions(
            biometricOnly: true, // Hanya izinkan biometric, bukan PIN/Pattern
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          // JIKA BERHASIL, BUAT SESSION
          box.write('isLoggedIn', true);
          Get.offAllNamed('/home');
        }
      } else {
        Get.snackbar("Info", "Perangkat tidak mendukung Biometric",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal melakukan autentikasi: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // 4. FUNGSI LOGOUT (SYARAT WAJIB MENU LOGOUT)
  void logout() {
    box.erase(); // Hapus semua data session (isLoggedIn jadi null)
    Get.offAllNamed('/login');
  }

  // Cek Status Login saat aplikasi dibuka (Auto Login)
  bool checkLoginStatus() {
    return box.read('isLoggedIn') ?? false;
  }
}