import 'dart:async';
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
  Timer? _checkerTimer;

  @override
  void initState() {
    super.initState();
    // SATPAM: Cek setiap 15 detik (lebih sering biar makin akurat)
    _checkerTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _checkAndTriggerAlarm();
      }
    });
    debugPrint("🚀 Satpam Alarm Mulai Bekerja...");
  }

  @override
  void dispose() {
    _checkerTimer?.cancel();
    super.dispose();
  }

  void _checkAndTriggerAlarm() {
    // Ambil waktu HP sekarang, hapus spasi, kecilkan semua huruf
    // Contoh: "10:30 PM" -> "10:30pm"
    final String now = TimeOfDay.now().format(context).replaceAll(' ', '').toLowerCase();
    
    final List<dynamic> alarms = dbService.getAlarmsFromActivity();

    debugPrint("🧐 Pengecekan Rutin: Jam Sekarang ($now)");

    for (var alarm in alarms) {
      // Bersihkan juga waktu yang tersimpan di database
      final String alarmTime = alarm['time'].toString().replaceAll(' ', '').toLowerCase();

      // DEBUG: Cek di console VS Code apakah jamnya sudah "bertemu"
      debugPrint("   --- Bandingkan: Database($alarmTime) vs Sekarang($now) | Status: ${alarm['isActive']}");

      if (alarm['isActive'] == true && alarmTime == now) {
        debugPrint("🔔 MATCH! Alarm Berbunyi Sekarang!");
        
        // Pemicu bunyi di DatabaseService
        dbService.triggerAlarm(
          alarm['time'].toString(), 
          alarm['label'].toString()
        );
        
        // Matikan status aktif agar tidak bunyi terus-menerus di menit yang sama
        int index = alarms.indexOf(alarm);
        dbService.updateAlarmStatus(index, false);
        
        if (mounted) setState(() {}); 
      }
    }
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
      middleText: "Jadwal ini mau dihapus, Dil?",
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