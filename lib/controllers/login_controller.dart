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

  void login(String username, String password) {
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