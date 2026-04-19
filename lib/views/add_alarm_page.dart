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

  final Color primaryColor = const Color(0xFF6B8E23); // Sage Green

  @override
  void initState() {
    super.initState();
    // Logika Edit: Kalau ada data lama, tampilkan. Kalau gak ada, pakai default.
    if (widget.existingData != null) {
      labelController = TextEditingController(text: widget.existingData!['label'] ?? "");
      isVibrate = widget.existingData!['isVibrate'] ?? true;
      
      String daysStr = widget.existingData!['days'] ?? "";
      if (daysStr != "Sekali") {
        selectedDays = daysStr.split(", ");
      }

      // Parsing format jam string (08:30 PM) balik ke TimeOfDay agar UI sinkron
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

  // Widget bantuan untuk angka jam aesthetic
  Widget _timeTile(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.green[900],
        fontSize: 80,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.green[900]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.existingData != null ? "Edit Jadwal" : "Tambah Jadwal",
          style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: primaryColor, size: 28),
            onPressed: () {
              // Menyiapkan data untuk dikirim balik ke AlarmPage
              final result = {
                "time": selectedTime.format(context).toString(),
                "days": selectedDays.isEmpty ? "Sekali" : selectedDays.join(", "),
                "label": labelController.text.isEmpty ? "Buang Sampah" : labelController.text,
                "isActive": true,
                "isVibrate": isVibrate,
              };

              // PENTING: triggerAlarm DIHAPUS dari sini agar nunggu waktu yang pas
              Get.back(result: result);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: selectedTime);
                if (picked != null) setState(() => selectedTime = picked);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeTile(selectedTime.hourOfPeriod.toString().padLeft(2, '0')),
                  Text(" : ", style: TextStyle(color: Colors.green[900], fontSize: 50)),
                  _timeTile(selectedTime.minute.toString().padLeft(2, '0')),
                  const SizedBox(width: 10),
                  Text(
                    selectedTime.period == DayPeriod.am ? "AM" : "PM",
                    style: TextStyle(color: Colors.green[900], fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            _buildSettingItem(Icons.repeat, "Ulangi", 
              selectedDays.isEmpty ? "Sekali" : selectedDays.join(", "), 
              () => _showDayPicker()),
            _buildSettingItem(Icons.label_outline, "Label", 
              labelController.text.isEmpty ? "Buang Sampah" : labelController.text, 
              () => _showLabelDialog()),
            _buildSettingItem(Icons.vibration, "Getar", 
              isVibrate ? "On" : "Off", 
              () => setState(() => isVibrate = !isVibrate)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(title, style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  void _showDayPicker() {
    Get.defaultDialog(
      title: "Pilih Hari",
      content: StatefulBuilder(builder: (context, setSt) {
        return Wrap(
          spacing: 8,
          children: days.map((d) => FilterChip(
            label: Text(d),
            selected: selectedDays.contains(d),
            onSelected: (v) => setSt(() => v ? selectedDays.add(d) : selectedDays.remove(d)),
          )).toList(),
        );
      }),
      onConfirm: () { setState(() {}); Get.back(); }
    );
  }

  void _showLabelDialog() {
    Get.defaultDialog(
      title: "Label Alarm",
      content: TextField(
        controller: labelController,
        decoration: const InputDecoration(hintText: "Misal: Sampah Plastik"),
      ),
      onConfirm: () { setState(() {}); Get.back(); }
    );
  }
}