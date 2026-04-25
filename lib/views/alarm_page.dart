import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import 'add_alarm_page.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final dbService = Get.find<DatabaseService>();
  final sessionBox = Hive.box(DatabaseService.sessionBox);

  @override
  Widget build(BuildContext context) {
    // 1. Ambil ID User yang sedang login
    final String currentUserId = sessionBox.get('currentUser', defaultValue: 'guest');

    // 2. Ambil semua alarm dan filter hanya untuk user ini
    final List<dynamic> allAlarms = dbService.getAlarmsFromActivity();
    final List<dynamic> userAlarms = allAlarms.where((alarm) => alarm['user'] == currentUserId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Jadwal Sampah",
          style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
        ),
      ),
      body: userAlarms.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: userAlarms.length,
              itemBuilder: (context, index) {
                final alarm = userAlarms[index];
                final bool isActive = alarm['isActive'] ?? true;
                
                // Cari index asli di database Hive agar tidak salah edit/hapus
                int originalIndex = allAlarms.indexOf(alarm);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onTap: () async {
                      // EDIT ALARM
                      final result = await Get.to(() => AddAlarmPage(
                        existingData: Map<String, dynamic>.from(alarm),
                        index: originalIndex,
                      ));

                      if (result != null) {
                        setState(() {
                          // Pastikan user ID tetap ada agar tidak hilang setelah edit
                          result['user'] = currentUserId; 
                          dbService.updateExistingAlarm(originalIndex, result);
                        });
                      }
                    },
                    title: Text(
                      alarm['time'],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isActive ? const Color(0xFF1B5E20) : Colors.grey[400],
                        letterSpacing: -1,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          alarm['label'],
                          style: TextStyle(
                            color: isActive ? Colors.black87 : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          alarm['days'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    // Trailing menggunakan Row agar tidak BOTTOM OVERFLOW
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            activeColor: const Color(0xFF2E7D32),
                            activeTrackColor: const Color(0xFFE8F5E9),
                            onChanged: (val) {
                              setState(() {
                                dbService.updateAlarmStatus(originalIndex, val);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 24),
                          onPressed: () => _confirmDelete(originalIndex),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          elevation: 4,
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
          onPressed: () async {
            // TAMBAH ALARM BARU
            final result = await Get.to(() => const AddAlarmPage());
            if (result != null) {
              setState(() {
                // Tambahkan field user agar terikat ke akun Dila
                result['user'] = currentUserId; 
                dbService.saveAlarmToActivity(result);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm_add_rounded, size: 70, color: Colors.green.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada jadwal buang sampah",
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int originalIndex) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, size: 35, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              const Text("Hapus Jadwal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Jadwal ini akan dihapus permanen dari akun kamu.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text("Batal", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        setState(() {
                          dbService.deleteAlarmFromActivity(originalIndex);
                        });
                        Get.back();
                      },
                      child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}