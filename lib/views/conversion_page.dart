import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/conversion_controller.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ConversionController()); // Inject Controller

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Eco-Traveler Tools ✈️", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A6741))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B8E23),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B8E23),
          tabs: const [Tab(text: "Currency"), Tab(text: "World Time")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrencyTab(), _buildTimeTab()],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Input Amount", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter IDR Amount",
                    prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF6B8E23)),
                    prefixText: "Rp ",
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Target Currency", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedCurrency.value,
                  decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF9F9F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
                  items: controller.currencyTips.keys.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => controller.selectedCurrency.value = value!,
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => _buildPrimaryButton(
            onPressed: controller.isLoadingCurrency.value ? null : controller.handleCurrencyConversion,
            isLoading: controller.isLoadingCurrency.value,
            text: "Calculate Eco-Exchange",
            icon: Icons.auto_awesome_outlined,
          )),
          const SizedBox(height: 40),
          Obx(() => _buildResultDisplay("${controller.resultCurrency.value.toStringAsFixed(2)} ${controller.selectedCurrency.value}", "Exchange Result")),
          const SizedBox(height: 24),
          Obx(() => _buildEcoTipBox(controller.currencyTips[controller.selectedCurrency.value]!)),
        ],
      ),
    );
  }

  Widget _buildTimeTab() {
    String localTime = DateFormat('HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCard(
            child: Column(
              children: [
                const Text("Your Local Time", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(localTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF4A6741))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Destination Timezone", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedTimezone.value,
                  decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF9F9F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
                  items: controller.timezones.entries.map((e) => DropdownMenuItem(value: e.value['zone'].toString(), child: Text(e.key))).toList(),
                  onChanged: (val) => controller.selectedTimezone.value = val!,
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => _buildPrimaryButton(
            onPressed: controller.isLoadingTime.value ? null : controller.handleTimeConversion,
            isLoading: controller.isLoadingTime.value,
            text: "Sync World Time",
            icon: Icons.public_rounded,
          )),
          const SizedBox(height: 40),
          Obx(() {
            if (controller.remoteTime.value == "--:--") return const Opacity(opacity: 0.5, child: Text("Results will appear here", style: TextStyle(fontStyle: FontStyle.italic)));
            return Column(
              children: [
                _buildResultDisplay(controller.remoteTime.value, controller.remoteDate.value),
                const SizedBox(height: 24),
                _buildEcoTipBox(
                  int.parse(controller.remoteTime.value.split(':')[0]) >= 18 || int.parse(controller.remoteTime.value.split(':')[0]) < 6
                  ? "Di tujuan sedang malam hari. Jangan lupa matikan perangkat yang tidak terpakai! 🌙"
                  : "Di sana sedang siang hari. Manfaatkan cahaya alami untuk menghemat listrik! ☀️"
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- Widget Helpers (UI tetap sama) ---
  Widget _buildEcoTipBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100)),
      child: Row(children: [const Icon(Icons.lightbulb_outline, color: Color(0xFF6B8E23)), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)))]),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]), child: child);
  }

  Widget _buildPrimaryButton({required VoidCallback? onPressed, required bool isLoading, required String text, required IconData icon}) {
    return SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: onPressed, icon: isLoading ? const SizedBox.shrink() : Icon(icon, color: Colors.white), label: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2)));
  }

  Widget _buildResultDisplay(String mainText, String subText) {
    return Column(children: [Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(15)), child: Text(mainText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)), textAlign: TextAlign.center))]);
  }
}