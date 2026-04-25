import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../services/database_service.dart';

class LoginController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // --- LOGIN MANUAL ---
  void login(String username, String password) {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar(
        "Peringatan",
        "Isi username dan password",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      var box = Hive.box(DatabaseService.authBox);
      var session = Hive.box(DatabaseService.sessionBox);
      String cleanUsername = username.trim();

      var userData = box.get('user_$cleanUsername');

      if (userData != null && userData['password'] == hashPassword(password)) {
        bool alreadyEnabled = session.get(
          'isBiometricEnabled',
          defaultValue: false,
        );
        String? lastUser = session.get('currentUser');

        _createSession(cleanUsername);

        Get.offAllNamed('/home');

        // LOGIKA POP-UP AESTHETIC
        if (!alreadyEnabled || lastUser != cleanUsername) {
          Future.delayed(const Duration(milliseconds: 800), () {
            _showOfferBiometricDialog(cleanUsername);
          });
        } else {
          Get.snackbar(
            "Selamat Datang",
            "Halo $cleanUsername!",
            backgroundColor: const Color(0xFF2E7D32),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Gagal",
          "Username atau Password salah",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Login error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- TAMPILAN POP-UP BIOMETRIK AESTHETIC ---
  void _showOfferBiometricDialog(String username) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon Lingkaran Hijau
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 50,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Aktifkan Biometrik?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Halo $username, mau masuk lebih cepat pakai sidik jari untuk sesi berikutnya?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 25),
              
              // Tombol Konfirmasi (Gradient)
              GestureDetector(
                onTap: () {
                  var session = Hive.box(DatabaseService.sessionBox);
                  session.put('currentUser', username);
                  session.put('isBiometricEnabled', true);
                  Get.back();
                  Get.snackbar(
                    "Berhasil",
                    "Biometrik aktif untuk $username",
                    backgroundColor: const Color(0xFF2E7D32),
                    colorText: Colors.white,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Ya, Aktifkan",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              
              // Tombol Nanti Saja
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Nanti Saja",
                  style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // --- LOGIN BIOMETRIK ---
  Future<void> loginWithBiometric() async {
    try {
      var session = Hive.box(DatabaseService.sessionBox);
      String? lastUser = session.get('currentUser');
      bool isBiometricEnabled = session.get(
        'isBiometricEnabled',
        defaultValue: false,
      );

      if (lastUser == null || lastUser.isEmpty || !isBiometricEnabled) {
        Get.snackbar(
          "Akses Ditolak",
          "Biometrik belum diaktifkan untuk akun manapun.",
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }

      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Gunakan sidik jari untuk masuk sebagai $lastUser',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          _createSession(lastUser);
          Get.offAllNamed('/home');
          Get.snackbar(
            "Berhasil",
            "Login biometrik sukses!",
            backgroundColor: const Color(0xFF2E7D32),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Info",
          "Perangkat tidak mendukung biometrik",
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Biometrik Gagal: $e");
    }
  }

  void _createSession(String username) {
    var session = Hive.box(DatabaseService.sessionBox);
    session.put('isLoggedIn', true);
    session.put('currentUser', username);
  }

  void logout(bool removeBiometric) {
    var session = Hive.box(DatabaseService.sessionBox);
    session.put('isLoggedIn', false);

    if (removeBiometric) {
      session.delete('currentUser');
      session.put('isBiometricEnabled', false);
      Get.snackbar("Log Out", "Akun dan tautan biometrik berhasil dilepas");
    } else {
      Get.snackbar("Log Out", "Berhasil keluar");
    }
    Get.offAllNamed('/login');
  }
}