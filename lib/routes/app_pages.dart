import 'package:get/get.dart';
import '../views/login_page.dart';
import '../views/dashboard_page.dart'; 

class AppRoutes {
  static const INITIAL = '/login';
  static final routes = [
    GetPage(name: '/login', page: () => const LoginPage()),
    GetPage(name: '/home', page: () => const DashboardPage()),
  ];
}