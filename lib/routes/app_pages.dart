import 'package:get/get.dart';
import '../views/login_page.dart';
import '../views/home_tab.dart';
import '../views/signup_page.dart'; 

class AppRoutes {
  static const initial = '/login';

  static final routes = [
    GetPage(name: '/login', page: () => const LoginPage()),

    GetPage(name: '/home', page: () => const HomeTab()),

    GetPage(name: '/signup', page: () => const SignUpPage()),
  ];
}
