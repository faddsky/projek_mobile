import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/conversion_controller.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ConversionController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Memicu timer di controller agar jam langsung berdetak saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.handleTimeConversion();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "Eco Tools",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: const Color(0xFF2E7D32),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: "Mata Uang"),
            Tab(text: "Waktu Dunia"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrencyTab(), _buildTimeTab()],
      ),
    );
  }

  // --- TAB MATA UANG ---
  Widget _buildCurrencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Jumlah Input",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Masukkan Jumlah IDR",
                    prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32)),
                    prefixText: "Rp ",
                    filled: true,
                    fillColor: const Color(0xFFF1F8E9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Mata Uang Tujuan",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCurrency.value,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F8E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: controller.currencyTips.keys
                        .map((String value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedCurrency.value = value;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _buildPrimaryButton(
              onPressed: controller.isLoadingCurrency.value
                  ? null
                  : controller.handleCurrencyConversion,
              isLoading: controller.isLoadingCurrency.value,
              text: "Hitung Kurs Eco",
              icon: Icons.monetization_on_rounded,
            ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => _buildResultDisplay(
              "${controller.resultCurrency.value.toStringAsFixed(2)} ${controller.selectedCurrency.value}",
              "Hasil Konversi",
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _buildEcoTipBox(
              controller.currencyTips[controller.selectedCurrency.value]!,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB WAKTU DUNIA ---
  Widget _buildTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCard(
            child: Column(
              children: [
                const Text(
                  "Waktu Lokal Kamu",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Obx ini akan rebuild setiap detik mengikuti timer di controller
                Obx(() {
                  controller.remoteTime.value; // Trigger rebuild
                  return Text(
                    DateFormat('HH:mm:ss').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20),
                      letterSpacing: -1,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Zona Waktu Tujuan",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedTimezone.value,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F8E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: controller.timezones.entries
                        .map((e) => DropdownMenuItem(
                              value: e.value['zone'].toString(),
                              child: Text(e.key),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectedTimezone.value = val;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _buildPrimaryButton(
              onPressed: controller.isLoadingTime.value
                  ? null
                  : controller.handleTimeConversion,
              isLoading: controller.isLoadingTime.value,
              text: "Sinkron Waktu Dunia",
              icon: Icons.public_rounded,
            ),
          ),
          const SizedBox(height: 32),
          Obx(() {
            if (controller.remoteTime.value.contains("--")) {
              return Text(
                "Pilih tujuan untuk sinkronisasi waktu",
                style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
              );
            }

            int hour = 0;
            try {
              hour = int.parse(controller.remoteTime.value.split(':')[0]);
            } catch (e) {
              hour = 0;
            }

            String tip = (hour >= 18 || hour < 6)
                ? "Di sana sudah malam. Jangan lupa matikan alat elektronik yang tidak dipakai! 🌙"
                : "Di sana sedang siang hari. Manfaatkan cahaya alami untuk hemat energi! ☀️";

            return Column(
              children: [
                _buildResultDisplay(controller.remoteTime.value, controller.remoteDate.value),
                const SizedBox(height: 24),
                _buildEcoTipBox(tip),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildEcoTipBox(String pesan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCEDC8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String text,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon, color: Colors.white),
        label: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResultDisplay(String teksUtama, String teksSub) {
    return Column(
      children: [
        Text(teksSub, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            teksUtama,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
          ),
        ),
      ],
    );
  }
}