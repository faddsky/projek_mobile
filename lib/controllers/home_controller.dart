import 'package:get/get.dart';
import 'package:projek_mobile/services/air_service.dart';
import 'package:projek_mobile/services/database_service.dart';

class HomeController extends GetxController {
  // --- Logika Udara ---
  var airData = Rxn<Map<String, dynamic>>();
  var locationName = "Mencari wilayah...".obs;
  var isLoading = true.obs;
  var hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
    // Cek tips harian otomatis tetap dipertahankan
    Get.find<DatabaseService>().checkAndSendGreenTip();
  }

  Future<void> fetchHomeData() async {
    try {
      isLoading(true);
      hasError(false);
      final data = await AirService().getAirData();
      airData.value = data;

      double lat = data['coord']['lat'];
      double lon = data['coord']['lon'];
      locationName.value = await AirService().getLocationName(lat, lon);
    } catch (e) {
      hasError(true);
    } finally {
      isLoading(false);
    }
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return "Selamat pagi,";
    if (hour < 15) return "Selamat siang,";
    if (hour < 18) return "Selamat sore,";
    return "Selamat malam,";
  }
}