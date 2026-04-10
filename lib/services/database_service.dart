import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DatabaseService extends GetxService {
  static const String authBox = 'auth_box';
  static const String profileBox = 'profile_box';
  static const String historyBox = 'history_box';
  static const String activityBox = 'activity_box';
  static const String sessionBox = 'session_box';

  // --- PLUGIN NOTIFIKASI ---
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<DatabaseService> init() async {
    await Hive.initFlutter();
    
    await Hive.openBox(authBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(historyBox);
    await Hive.openBox(activityBox);
    await Hive.openBox(sessionBox);

    // Inisialisasi notifikasi saat database siap
    await _initNotifications();
    
    return this;
  }

  // --- SETUP NOTIFIKASI ---
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Meminta izin agar tombol di setting tidak abu-abu
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- PEMICU ALARM (KRING KRING) ---
  Future<void> triggerAlarm(String time, String label) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'eco_step_alarm',
      'Alarm Sampah',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      "Waktunya Buang Sampah! 🚛",
      "Jadwal: $label ($time)",
      platformChannelSpecifics,
    );

    Get.snackbar(
      "ALARM AKTIF!",
      "Saatnya: $label",
      backgroundColor: Colors.white,
      icon: const Icon(Icons.alarm_on, color: Color(0xFF6B8E23)),
      duration: const Duration(seconds: 5),
    );
  }

  // --- FUNGSI ALARM (ACTIVITY BOX) ---
  List<dynamic> getAlarmsFromActivity() {
    return Hive.box(activityBox).get('alarm_list', defaultValue: []);
  }

  void saveAlarmToActivity(Map<String, dynamic> alarmData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms.add(alarmData);
    box.put('alarm_list', currentAlarms);
  }

  void updateExistingAlarm(int index, Map<String, dynamic> newData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms[index] = newData;
    box.put('alarm_list', currentAlarms);
  }

  void deleteAlarmFromActivity(int index) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms.removeAt(index);
    box.put('alarm_list', currentAlarms);
  }

  void updateAlarmStatus(int index, bool status) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms[index]['isActive'] = status;
    box.put('alarm_list', currentAlarms);
  }

  // --- FUNGSI DEBUG (SOLUSI BIAR LOGIN GAK ERROR) ---
  void debugCekSemuaBox() {
    List<String> semuaBox = [authBox, profileBox, historyBox, activityBox, sessionBox];
    debugPrint("========== MONITORING DATABASE ==========");
    for (String namaBox in semuaBox) {
      if (Hive.isBoxOpen(namaBox)) {
        var box = Hive.box(namaBox);
        debugPrint("📦 BOX: $namaBox (${box.length} data)");
      }
    }
  }

  // --- FUNGSI ASLI KAMU (TETAP TERJAGA) ---
  String hashPassword(String password) {
    var bytes = utf8.encode(password); 
    return sha256.convert(bytes).toString();
  }

  void saveScanResult(String label, double confidence, String funFact) {
    var box = Hive.box(historyBox);
    box.add({
      'label': label,
      'confidence': confidence,
      'funFact': funFact,
      'dateTime': DateTime.now().toString(),
    });
  }
}