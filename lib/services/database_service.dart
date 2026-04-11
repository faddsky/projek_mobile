import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';

class DatabaseService extends GetxService {
  static const String authBox = 'auth_box';
  static const String profileBox = 'profile_box';
  static const String historyBox = 'history_box';
  static const String activityBox = 'activity_box';
  static const String sessionBox = 'session_box';
  static const String notificationBox = 'notification_box'; 

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<DatabaseService> init() async {
    await Hive.initFlutter();
    
    await Hive.openBox(authBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(historyBox);
    await Hive.openBox(activityBox);
    await Hive.openBox(sessionBox);
    await Hive.openBox(notificationBox);

    // 1. Inisialisasi Zona Waktu
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    await _initNotifications();
    return this;
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- FITUR: RIWAYAT NOTIFIKASI ---
  void saveNotification(String title, String body) {
    var box = Hive.box(notificationBox);
    List<dynamic> logs = box.get('logs', defaultValue: []);
    logs.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toString(),
      'isRead': false,
    });
    box.put('logs', logs);
  }

  List<dynamic> getAllNotifications() {
    return Hive.box(notificationBox).get('logs', defaultValue: []);
  }

  // --- HITUNG NOTIFIKASI BELUM DIBACA ---
  int getUnreadCount() {
    var logs = getAllNotifications();
    return logs.where((item) => item['isRead'] == false).length;
  }

  // --- TANDAI SEMUA SUDAH DIBACA ---
  void markAllAsRead() {
    var box = Hive.box(notificationBox);
    List<dynamic> logs = box.get('logs', defaultValue: []);
    for (var item in logs) {
      item['isRead'] = true;
    }
    box.put('logs', logs);
  }

  // --- FITUR: GREEN TIPS HARIAN ---
  void checkAndSendGreenTip() {
    var box = Hive.box(notificationBox);
    String lastSent = box.get('last_tip_date', defaultValue: "");
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastSent != today) {
      List<String> tips = [
        "Mengurangi satu kantong plastik hari ini sangat berarti loh! ✨",
        "Gunakan botol minum sendiri yuk untuk mengurangi sampah plastik! 🥤",
        "Sampah organik bisa jadi kompos yang bermanfaat bagi tanamanmu. 🌱",
        "Pilah sampahmu hari ini agar bumi tetap cantik! 🌸"
      ];
      String tipHariIni = (tips..shuffle()).first;
      triggerAlarm(DateFormat.jm().format(DateTime.now()), tipHariIni);
      saveNotification("Green Tips Hari Ini", tipHariIni);
      box.put('last_tip_date', today);
    }
  }

  // --- LOGIKA PENJADWALAN ALARM ---
  Future<void> _scheduleAlarmNotification(int id, Map<String, dynamic> alarmData) async {
    if (alarmData['isActive'] == false) {
      await _notificationsPlugin.cancel(id);
      return;
    }

    try {
      final String timeStr = alarmData['time'].toString().toUpperCase();
      DateTime parsedTime;
      try {
        parsedTime = DateFormat.jm().parse(timeStr);
      } catch (_) {
        parsedTime = DateFormat("hh:mma").parse(timeStr.replaceAll(" ", ""));
      }
      
      final DateTime now = DateTime.now();
      DateTime scheduledDate = DateTime(
        now.year, now.month, now.day, 
        parsedTime.hour, parsedTime.minute
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        "Waktunya Buang Sampah! 🚛",
        "Jadwal: ${alarmData['label']}",
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'eco_step_alarm',
            'Alarm Sampah',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      saveNotification("Jadwal Diatur", "Alarm '${alarmData['label']}' disiapkan untuk jam ${alarmData['time']}");
      debugPrint("⏰ Berhasil dijadwalkan: ${alarmData['label']} @ $scheduledDate");
    } catch (e) {
      debugPrint("❌ Gagal menjadwalkan alarm: $e");
    }
  }

  // --- PEMICU ALARM MANUAL ---
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

  // --- FUNGSI HIVE DASAR ---
  List<dynamic> getAlarmsFromActivity() {
    return Hive.box(activityBox).get('alarm_list', defaultValue: []);
  }

  void saveAlarmToActivity(Map<String, dynamic> alarmData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms.add(alarmData);
    box.put('alarm_list', currentAlarms);
    _scheduleAlarmNotification(currentAlarms.length - 1, alarmData);
  }

  void updateExistingAlarm(int index, Map<String, dynamic> newData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms[index] = newData;
    box.put('alarm_list', currentAlarms);
    _scheduleAlarmNotification(index, newData);
  }

  void deleteAlarmFromActivity(int index) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms.removeAt(index);
    box.put('alarm_list', currentAlarms);
    _notificationsPlugin.cancel(index);
  }

  void updateAlarmStatus(int index, bool status) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms[index]['isActive'] = status;
    box.put('alarm_list', currentAlarms);
    _scheduleAlarmNotification(index, currentAlarms[index]);
  }

  void debugCekSemuaBox() {
    List<String> semuaBox = [authBox, profileBox, historyBox, activityBox, sessionBox, notificationBox];
    debugPrint("========== MONITORING DATABASE ==========");
    for (String namaBox in semuaBox) {
      if (Hive.isBoxOpen(namaBox)) {
        var box = Hive.box(namaBox);
        debugPrint("📦 BOX: $namaBox (${box.length} data)");
      }
    }
  }

  // --- FUNGSI ASLI USER ---
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
    if (box.length % 5 == 0) {
      saveNotification("Hebat!", "Kamu sudah melakukan scan sebanyak ${box.length} kali! 🌱");
    }
  }

  // --- FUNGSI POIN GAME (BARU) ---
  int getTotalPoints() {
    return Hive.box(profileBox).get('total_points', defaultValue: 0);
  }

  void addGamePoints(int newPoints) {
    var box = Hive.box(profileBox);
    int currentPoints = getTotalPoints();
    box.put('total_points', currentPoints + newPoints);
    debugPrint("🎉 Poin berhasil disimpan! Total sekarang: ${currentPoints + newPoints}");
  }
}