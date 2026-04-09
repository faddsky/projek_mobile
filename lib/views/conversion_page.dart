import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  
  // Data dummy kurs (Syarat: Minimal 3 mata uang)
  double resultCurrency = 0;
  String selectedCurrency = 'USD';
  final Map<String, double> rates = {
    'USD': 15800.0,
    'SGD': 11700.0,
    'EUR': 17100.0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Convert", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A6741),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A6741),
          indicatorColor: const Color(0xFF6B8E23),
          tabs: const [
            Tab(icon: Icon(Icons.money), text: "Mata Uang"),
            Tab(icon: Icon(Icons.access_time), text: "Waktu Dunia"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimeTab(),
        ],
      ),
    );
  }

  // --- TAB MATA UANG ---
  Widget _buildCurrencyTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Masukkan Rupiah (IDR)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              prefixText: "Rp ",
            ),
            onChanged: (value) {
              setState(() {
                double amount = double.tryParse(value) ?? 0;
                resultCurrency = amount / rates[selectedCurrency]!;
              });
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedCurrency,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            items: rates.keys.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text("Ke $value"));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCurrency = value!;
                double amount = double.tryParse(_amountController.text) ?? 0;
                resultCurrency = amount / rates[selectedCurrency]!;
              });
            },
          ),
          const SizedBox(height: 30),
          Text("Hasil Konversi:", style: TextStyle(color: Colors.grey[600])),
          Text("${resultCurrency.toStringAsFixed(2)} $selectedCurrency",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6B8E23))),
        ],
      ),
    );
  }

  // --- TAB WAKTU (WIB, WITA, WIT, LONDON) ---
  Widget _buildTimeTab() {
    // Logic zona waktu sederhana
    DateTime now = DateTime.now().toUtc(); // Baseline UTC
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _timeCard("WIB (Jakarta)", now.add(const Duration(hours: 7))),
        _timeCard("WITA (Bali)", now.add(const Duration(hours: 8))),
        _timeCard("WIT (Papua)", now.add(const Duration(hours: 9))),
        _timeCard("London (BST/GMT)", now.add(const Duration(hours: 1))), // Sesuai musim/saat ini
      ],
    );
  }

  Widget _timeCard(String label, DateTime time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(DateFormat('HH:mm').format(time),
            style: const TextStyle(fontSize: 20, color: Color(0xFF6B8E23), fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('EEEE, dd MMM').format(time)),
      ),
    );
  }
}