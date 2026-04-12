import 'package:get/get.dart';
import '../views/login_page.dart';
import '../views/home_tab.dart'; 
import '../views/signup_page.dart'; // Tambahkan jika kamu masih butuh rute signup

class AppRoutes {
  static const INITIAL = '/login';

  static final routes = [
    // Rute untuk Halaman Login
    GetPage(
      name: '/login', 
      page: () => const LoginPage(),
    ),
    
    // Rute untuk Halaman Home (Sekarang langsung ke HomeTab)
    GetPage(
      name: '/home', 
      page: () => const HomeTab(),
    ),

    // Tambahkan rute signup jika masih digunakan
    GetPage(
      name: '/signup', 
      page: () => const SignUpPage(),
    ),
  ];
}