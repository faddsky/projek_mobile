import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAlarmPage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final int? index;

  const AddAlarmPage({super.key, this.existingData, this.index});

  @override
  State<AddAlarmPage> createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  late TimeOfDay selectedTime;
  late TextEditingController labelController;
  List<String> days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
  List<String> selectedDays = [];
  bool isVibrate = true;

  // Warna Konsisten Emerald
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color scaffoldBg = const Color(0xFFF8FAF8);

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      labelController = TextEditingController(text: widget.existingData!['label'] ?? "");
      isVibrate = widget.existingData!['isVibrate'] ?? true;
      
      String daysStr = widget.existingData!['days'] ?? "";
      if (daysStr != "Sekali") {
        selectedDays = daysStr.split(", ");
      }

      try {
        final String timeStr = widget.existingData!['time'].toString();
        final parts = timeStr.split(" ");
        final hm = parts[0].split(":");
        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);
        if (parts[1] == "PM" && hour != 12) hour += 12;
        if (parts[1] == "AM" && hour == 12) hour = 0;
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        selectedTime = TimeOfDay.now();
      }
    } else {
      selectedTime = TimeOfDay.now();
      labelController = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.green[900]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.existingData != null ? "Ubah Jadwal" : "Tambah Jadwal",
          style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                final result = {
                  "time": selectedTime.format(context).toString(),
                  "days": selectedDays.isEmpty ? "Sekali" : selectedDays.join(", "),
                  "label": labelController.text.isEmpty ? "Buang Sampah" : labelController.text,
                  "isActive": true,
                  "isVibrate": isVibrate,
                };
                Get.back(result: result);
              },
              child: Text(
                "SIMPAN",
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Digital Time Picker Style
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context, 
                  initialTime: selectedTime,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(primary: primaryColor),
                      ),
                      child: child!,
                    );
                  }
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _timeUnit(selectedTime.hourOfPeriod.toString().padLeft(2, '0')),
                    Text(":", style: TextStyle(color: primaryColor, fontSize: 40, fontWeight: FontWeight.bold)),
                    _timeUnit(selectedTime.minute.toString().padLeft(2, '0')),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        _periodUnit("AM", selectedTime.period == DayPeriod.am),
                        const SizedBox(height: 5),
                        _periodUnit("PM", selectedTime.period == DayPeriod.pm),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Menu Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.repeat_rounded, 
                      "Ulangi", 
                      selectedDays.isEmpty ? "Sekali" : selectedDays.join(", "), 
                      () => _showDayPicker()
                    ),
                    Divider(height: 1, color: Colors.grey[100], indent: 60),
                    _buildSettingItem(
                      Icons.label_important_outline_rounded, 
                      "Label", 
                      labelController.text.isEmpty ? "Buang Sampah" : labelController.text, 
                      () => _showLabelDialog()
                    ),
                    Divider(height: 1, color: Colors.grey[100], indent: 60),
                    _buildSettingItem(
                      Icons.vibration_rounded, 
                      "Getar", 
                      isVibrate ? "Aktif" : "Mati", 
                      () => setState(() => isVibrate = !isVibrate),
                      isSwitch: true
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeUnit(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 70,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1B5E20),
        letterSpacing: -2,
      ),
    );
  }

  Widget _periodUnit(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isActive ? primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String sub, VoidCallback onTap, {bool isSwitch = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      trailing: isSwitch 
        ? Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isVibrate, 
              onChanged: (v) => setState(() => isVibrate = v),
              activeColor: primaryColor,
            ),
          )
        : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  void _showDayPicker() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Hari", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              StatefulBuilder(builder: (context, setSt) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: days.map((d) {
                    bool isSelected = selectedDays.contains(d);
                    return ChoiceChip(
                      label: Text(d),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      onSelected: (v) => setSt(() => v ? selectedDays.add(d) : selectedDays.remove(d)),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () { setState(() {}); Get.back(); },
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLabelDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Label Jadwal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: scaffoldBg,
                  hintText: "Misal: Sampah Plastik",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () { setState(() {}); Get.back(); },
                  child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}