import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Variabel Mata Uang ---
  final TextEditingController _amountController = TextEditingController();
  double resultCurrency = 0;
  String selectedCurrency = 'USD';
  bool isLoadingCurrency = false;

  // --- Variabel Waktu Dunia ---
  String selectedTimezone = 'Asia/Jakarta';
  String remoteTime = "--:--";
  String remoteDate = "";
  bool isLoadingTime = false;

  // Daftar zona waktu untuk Dropdown
  final Map<String, String> timezones = {
    'WIB (Jakarta)': 'Asia/Jakarta',
    'WITA (Bali/Makassar)': 'Asia/Makassar',
    'WIT (Papua)': 'Asia/Jayapura',
    'London (UK)': 'Europe/London',
    'Tokyo (Japan)': 'Asia/Tokyo',
    'New York (US)': 'America/New_York',
    'Seoul (South Korea)': 'Asia/Seoul',
    'Makkah (Saudi Arabia)': 'Asia/Riyadh',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIC: KONVERSI MATA UANG ---
  Future<void> _handleCurrencyConversion() async {
    if (_amountController.text.isEmpty) return;
    setState(() => isLoadingCurrency = true);

    final apiKey = dotenv.env['KURS_API_KEY'];
    final url =
        "https://v6.exchangerate-api.com/v6/$apiKey/pair/IDR/$selectedCurrency";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double rate = data['conversion_rate'];
        double amount = double.tryParse(_amountController.text) ?? 0;
        setState(() => resultCurrency = amount * rate);
      }
    } catch (e) {
      _showErrorSnackBar("Gagal mengambil data kurs.");
    } finally {
      setState(() => isLoadingCurrency = false);
    }
  }

  // --- LOGIC: KONVERSI WAKTU (SINGLE REQUEST) ---
  Future<void> _handleTimeConversion() async {
    setState(() => isLoadingTime = true);
    try {
      final data = await ApiService.getWorldTime(selectedTimezone);
      setState(() {
        remoteTime = data['time'];
        remoteDate = "${data['dayOfWeek']}, ${data['date']}";
      });
    } catch (e) {
      _showErrorSnackBar("Gagal mengambil waktu dunia.");
    } finally {
      setState(() => isLoadingTime = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "Eco Convert 🌿",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A6741),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A6741),
          indicatorColor: const Color(0xFF6B8E23),
          tabs: const [
            Tab(icon: Icon(Icons.monetization_on), text: "Mata Uang"),
            Tab(icon: Icon(Icons.public), text: "Waktu Dunia"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrencyTab(), _buildTimeTab()],
      ),
    );
  }

  // --- TAB 1: MATA UANG ---
  Widget _buildCurrencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Masukkan Rupiah (IDR)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              prefixText: "Rp ",
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedCurrency,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: ['USD', 'SGD', 'EUR', 'JPY', 'SAR', 'KRW'].map((
              String value,
            ) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text("Konversi ke $value"),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedCurrency = value!),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoadingCurrency ? null : _handleCurrencyConversion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoadingCurrency
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Hitung Sekarang",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 40),
          const Text("Hasil Konversi:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            "${resultCurrency.toStringAsFixed(2)} $selectedCurrency",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B8E23),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: WAKTU DUNIA ---
  Widget _buildTimeTab() {
    String localTime = DateFormat('HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget Waktu Lokal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              children: [
                const Text(
                  "Waktu Lokal Kamu (Sekarang)",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  localTime,
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6741),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Pilih Zona Waktu Tujuan:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedTimezone,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: timezones.entries.map((e) {
              return DropdownMenuItem(value: e.value, child: Text(e.key));
            }).toList(),
            onChanged: (val) => setState(() => selectedTimezone = val!),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: isLoadingTime ? null : _handleTimeConversion,
              icon: const Icon(Icons.language, color: Colors.white),
              label: const Text(
                "Cek Waktu Sekarang",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Hasil Konversi Waktu
          Center(
            child: Column(
              children: [
                if (isLoadingTime)
                  const CircularProgressIndicator(color: Color(0xFF6B8E23))
                else ...[
                  Text(
                    remoteTime,
                    style: const TextStyle(
                      fontSize: 65,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                  Text(
                    remoteDate,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (remoteTime != "--:--")
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedTimezone,
                        style: const TextStyle(
                          color: Color(0xFF4A6741),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
