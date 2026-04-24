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
      );
      return;
    }

    isLoading.value = true;
    try {
      var box = Hive.box(DatabaseService.authBox);
      var userData = box.get('user_${username.trim()}');

      if (userData != null && userData['password'] == hashPassword(password)) {
        _createSession(username.trim());

        // --- LOGIKA PENAWARAN BIOMETRIK ---
        var session = Hive.box(DatabaseService.sessionBox);
        String? biometricUser = session.get('currentUser');

        // Jika di HP ini belum ada user yang terdaftar biometrik
        if (biometricUser == null || biometricUser.isEmpty) {
          Get.offAllNamed('/home'); // Pindah ke home dulu

          // Munculkan dialog setelah delay kecil agar transisi halaman selesai
          Future.delayed(const Duration(milliseconds: 600), () {
            _showOfferBiometricDialog(username.trim());
          });
        } else {
          Get.offAllNamed('/home');
          Get.snackbar(
            "Selamat Datang",
            "Halo $username!",
            backgroundColor: Colors.green,
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

  // Fungsi Dialog Penawaran
  void _showOfferBiometricDialog(String username) {
    Get.defaultDialog(
      title: "Aktifkan Biometrik? 🔒",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText:
          "Halo $username, mau masuk lebih cepat pakai sidik jari untuk sesi berikutnya?",
      textConfirm: "Ya, Aktifkan",
      textCancel: "Nanti Saja",
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF6B8E23), // Warna hijau tema kamu
      onConfirm: () {
        var session = Hive.box(DatabaseService.sessionBox);
        // Daftarkan user ini sebagai pemilik biometrik di HP ini
        session.put('currentUser', username);
        Get.back();
        Get.snackbar(
          "Berhasil",
          "Biometrik aktif untuk $username",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  // --- LOGIN BIOMETRIK (SUDAH DIPERBAIKI) ---
  Future<void> loginWithBiometric() async {
    try {
      var session = Hive.box(DatabaseService.sessionBox);
      // 1. Ambil siapa user terakhir yang login di HP ini
      String? lastUser = session.get('currentUser');

      // 2. Jika tidak ada user (null atau kosong), jangan jalankan biometrik
      if (lastUser == null || lastUser.isEmpty) {
        Get.snackbar(
          "Akses Ditolak",
          "Belum ada akun yang terikat di HP ini. Silakan login manual dulu.",
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
          // 3. Login sukses, buat sesi untuk user tersebut
          _createSession(lastUser);
          Get.offAllNamed('/home');
          Get.snackbar(
            "Berhasil",
            "Login biometrik sukses!",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Info",
          "Perangkat tidak mendukung biometrik",
          backgroundColor: Colors.blueAccent,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Biometrik Gagal: $e");
    }
  }

  void _createSession(String username) {
    var session = Hive.box(DatabaseService.sessionBox);
    session.put('isLoggedIn', true);
    session.put(
      'currentUser',
      username,
    ); // Menyimpan username untuk biometrik nanti
  }

  void logout(bool removeBiometric) {
    var session = Hive.box(DatabaseService.sessionBox);

    // Matikan status login
    session.put('isLoggedIn', false);

    if (removeBiometric) {
      // Menghapus username yang tertaut, sehingga tombol biometrik jadi abu-abu lagi
      session.delete('currentUser');
      Get.snackbar("Log Out", "Akun dan tautan biometrik berhasil dilepas");
    } else {
      Get.snackbar("Log Out", "Berhasil keluar");
    }

    Get.offAllNamed('/login');
  }
}
