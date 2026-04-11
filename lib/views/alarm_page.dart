import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import 'add_alarm_page.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final dbService = Get.find<DatabaseService>();

  @override
  void initState() {
    super.initState();
    // LOG: Sekarang pengecekan manual (Timer) dihapus karena sudah
    // menggunakan ZonedSchedule di DatabaseService agar bunyi di background.
    debugPrint("🔔 Sistem Alarm Otomatis Aktif di Background...");
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data terbaru setiap build
    final List<dynamic> alarms = dbService.getAlarmsFromActivity();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), // Sage muda banget
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.green[900]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Jadwal Sampah",
          style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
        ),
      ),
      body: alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Belum ada jadwal", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                final bool isActive = alarm['isActive'] ?? true;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    onTap: () async {
                      // Navigasi ke Edit
                      final result = await Get.to(() => AddAlarmPage(
                        existingData: Map<String, dynamic>.from(alarm),
                        index: index,
                      ));

                      if (result != null) {
                        setState(() {
                          dbService.updateExistingAlarm(index, result);
                        });
                      }
                    },
                    title: Text(
                      alarm['time'],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: isActive ? Colors.green[900] : Colors.grey,
                      ),
                    ),
                    subtitle: Text("${alarm['label']} | ${alarm['days']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isActive,
                          activeColor: const Color(0xFF6B8E23),
                          onChanged: (val) {
                            setState(() {
                              dbService.updateAlarmStatus(index, val);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B8E23),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () async {
          final result = await Get.to(() => const AddAlarmPage());
          if (result != null) {
            setState(() {
              dbService.saveAlarmToActivity(result);
            });
          }
        },
      ),
    );
  }

  void _confirmDelete(int index) {
    Get.defaultDialog(
      title: "Hapus?",
      middleText: "Jadwal ini mau dihapus?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        setState(() {
          dbService.deleteAlarmFromActivity(index);
        });
        Get.back();
      },
    );
  }
}