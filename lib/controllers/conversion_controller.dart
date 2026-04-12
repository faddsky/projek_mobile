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
  var remoteTime = "--:--".obs;
  var remoteDate = "".obs;
  var isLoadingTime = false.obs;

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

  // --- Logic: Konversi Mata Uang ---
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
      Get.snackbar("Error", "Gagal mengambil data kurs.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoadingCurrency.value = false;
    }
  }

  // --- Logic: Konversi Waktu ---
  void handleTimeConversion() {
    isLoadingTime.value = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      DateTime nowUtc = DateTime.now().toUtc();
      int offset = timezones.entries
          .firstWhere((e) => e.value['zone'] == selectedTimezone.value)
          .value['offset'];

      DateTime targetTime = nowUtc.add(Duration(hours: offset));
      List<String> days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
      String dayName = days[targetTime.weekday % 7];
      
      remoteTime.value = DateFormat('HH:mm').format(targetTime);
      remoteDate.value = "$dayName, ${targetTime.day}-${targetTime.month}-${targetTime.year}";
      isLoadingTime.value = false;
    });
  }
}