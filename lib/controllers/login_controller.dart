import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../services/database_service.dart';

class LoginController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;
  var selectedImagePath = ''.obs;

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

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
    // Validasi input kosong
    if (username.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar("Error", "Semua field harus diisi", backgroundColor: Colors.orangeAccent);
      return;
    }

    isLoading.value = true;
    try {
      var box = Hive.box(DatabaseService.authBox);
      
      // Bersihkan input dari spasi yang tidak sengaja
      String cleanUsername = username.trim();
      String cleanEmail = email.trim().toLowerCase();

      // 1. Validasi Username (Case Sensitive berdasarkan Key)
      if (box.containsKey('user_$cleanUsername')) {
        Get.snackbar("Gagal", "Username '$cleanUsername' sudah terdaftar!", 
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        isLoading.value = false;
        return; // Berhenti di sini jika username ada
      }

      // 2. Validasi Email (Looping untuk cek value di dalam Map)
      var allUsers = box.values.toList();
      bool isEmailExist = allUsers.any((user) {
        if (user is Map) {
          return user['email'].toString().toLowerCase() == cleanEmail;
        }
        return false;
      });

      if (isEmailExist) {
        Get.snackbar("Gagal", "Email '$cleanEmail' sudah digunakan!", 
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        isLoading.value = false;
        return; // Berhenti di sini jika email ada
      }

      // 3. Simpan jika semua validasi lolos
      await box.put('user_$cleanUsername', {
        'username': cleanUsername,
        'email': cleanEmail,
        'password': hashPassword(password),
        'profilePic': selectedImagePath.value,
      });

      Get.snackbar("Berhasil", "Akun $cleanUsername berhasil dibuat!", 
          backgroundColor: Colors.green, colorText: Colors.white);
      
      selectedImagePath.value = ''; 
      Future.delayed(const Duration(milliseconds: 1500), () => Get.back()); 
      
    } catch (e) {
      Get.snackbar("Error", "Gagal mendaftar: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void login(String username, String password) {
    Get.find<DatabaseService>().debugCekSemuaBox();
    if (username.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar("Peringatan", "Isi username dan password", backgroundColor: Colors.orangeAccent);
      return;
    }

    isLoading.value = true;
    try {
      var box = Hive.box(DatabaseService.authBox);
      var userData = box.get('user_${username.trim()}');

      if (userData != null && userData['password'] == hashPassword(password)) {
        _createSession(username.trim());
        Get.offAllNamed('/home');
        Get.snackbar("Selamat Datang", "Halo $username!", backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Gagal", "Username atau Password salah", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Login error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithBiometric() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Gunakan sidik jari untuk masuk ke EcoStep',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );

        if (didAuthenticate) {
          var session = Hive.box(DatabaseService.sessionBox);
          String lastUser = session.get('currentUser') ?? "User";
          _createSession(lastUser);
          Get.offAllNamed('/home');
        }
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

  void logout() {
    var session = Hive.box(DatabaseService.sessionBox);
    session.put('isLoggedIn', false);
    Get.offAllNamed('/login');
  }
}