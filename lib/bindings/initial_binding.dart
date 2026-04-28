import 'package:get/get.dart';
import 'package:projek_mobile/services/database_service.dart';
import '../controllers/login_controller.dart';
import '../controllers/home_controller.dart'; 

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Memastikan DatabaseService siap digunakan di seluruh aplikasi
    Get.lazyPut<DatabaseService>(() => DatabaseService());

    // Pendaftaran Controller untuk Login
    Get.lazyPut<LoginController>(() => LoginController());

    Get.lazyPut<HomeController>(() => HomeController());
  }
}