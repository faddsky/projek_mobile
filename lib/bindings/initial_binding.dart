import 'package:get/get.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/login_controller.dart';
import '../controllers/home_controller.dart'; // Ganti ke HomeController

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Memastikan DatabaseService siap digunakan di seluruh aplikasi
    Get.lazyPut<DatabaseService>(() => DatabaseService());

    // Pendaftaran Controller untuk Login
    Get.lazyPut<LoginController>(() => LoginController());

    // Sekarang kita menggunakan HomeController sebagai pusat logika di Home
    // DashboardController sudah tidak perlu didaftarkan lagi karena sudah digabung
    Get.lazyPut<HomeController>(() => HomeController());
  }
}