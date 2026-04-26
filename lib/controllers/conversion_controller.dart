import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConversionController extends GetxController {
  // --- State Mata Uang ---
  final amountController = TextEditingController();
  var resultCurrency = 0.0.obs;
  var selectedCurrency = 'USD'.obs;
  var isLoadingCurrency = false.obs;

  // --- State Waktu Dunia ---
  var selectedTimezone = 'Asia/Jakarta'.obs;
  var remoteTime = "--:--:--".obs;
  var remoteDate = "".obs;
  var isLoadingTime = false.obs;
  
  Timer? _timer;

  // Variabel yang tadi hilang (Penyebab Error)
  final Map<String, String> currencyTips = {
    'USD': 'Gunakan tumbler di US bisa dapet diskon kopi di banyak kedai! ☕',
    'SGD': 'Singapura punya sistem MRT yang sangat bersih dan hemat emisi! 🚆',
    'EUR': 'Eropa sangat ramah sepeda, cobalah sewa sepeda untuk keliling kota! 🚲',
    'JPY': 'Jangan lupa bawa tas belanja sendiri, kresek di Jepang berbayar! 🛍️',
    'SAR': 'Gunakan transportasi umum bus modern untuk mengurangi jejak karbon! 🚌',
    'KRW': 'Sistem sortir sampah di Korea sangat ketat, perhatikan labelnya ya! ♻️',
  };

  final Map<String, Map<String, dynamic>> timezones = {
    'WIB (Jakarta)': {'zone': 'Asia/Jakarta', 'offset': 7},
    'WITA (Bali/Makassar)': {'zone': 'Asia/Makassar', 'offset': 8},
    'WIT (Papua)': {'zone': 'Asia/Jayapura', 'offset': 9},
    'London (UK)': {'zone': 'Europe/London', 'offset': 1},
    'Tokyo (Japan)': {'zone': 'Asia/Tokyo', 'offset': 9},
    'New York (US)': {'zone': 'America/New_York', 'offset': -4},
    'Seoul (South Korea)': {'zone': 'Asia/Seoul', 'offset': 9},
    'Makkah (Saudi Arabia)': {'zone': 'Asia/Riyadh', 'offset': 3},
  };

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> handleCurrencyConversion() async {
    if (amountController.text.isEmpty) return;
    isLoadingCurrency.value = true;
    final apiKey = dotenv.env['KURS_API_KEY'];
    final url = "https://v6.exchangerate-api.com/v6/$apiKey/pair/IDR/${selectedCurrency.value}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double rate = data['conversion_rate'];
        double amount = double.tryParse(amountController.text) ?? 0;
        resultCurrency.value = amount * rate;
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data kurs.");
    } finally {
      isLoadingCurrency.value = false;
    }
  }

  void handleTimeConversion() {
    _timer?.cancel();
    isLoadingTime.value = true;
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      isLoadingTime.value = false;
    });
  }

  void _updateClock() {
    DateTime nowUtc = DateTime.now().toUtc();
    int offset = timezones.values
        .firstWhere((e) => e['zone'] == selectedTimezone.value)['offset'];
    DateTime targetTime = nowUtc.add(Duration(hours: offset));
    List<String> days = ["", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"];
    String dayName = days[targetTime.weekday];
    remoteTime.value = DateFormat('HH:mm:ss').format(targetTime);
    remoteDate.value = "$dayName, ${targetTime.day}-${targetTime.month}-${targetTime.year}";
  }
}