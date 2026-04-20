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
  // Variabel reaktif untuk memantau jumlah notifikasi belum dibaca
  var unreadCount = 0.obs;

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

    // Inisialisasi angka unreadCount saat aplikasi dibuka
    updateUnreadCount();

    // Inisialisasi Zona Waktu
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

  // --- FUNGSI UPDATE ANGKA REAKTIF ---
  void updateUnreadCount() {
    var logs = getAllNotifications();
    unreadCount.value = logs.where((item) => item['isRead'] == false).length;
  }

  // --- FITUR: RIWAYAT NOTIFIKASI ---
  void saveNotification(String title, String body) {
    var box = Hive.box(notificationBox);
    List<dynamic> logs = List.from(box.get('logs', defaultValue: []));
    logs.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toString(),
      'isRead': false,
    });
    box.put('logs', logs);
    
    // Update angka setiap ada notifikasi baru
    updateUnreadCount();
  }

  List<dynamic> getAllNotifications() {
    return Hive.box(notificationBox).get('logs', defaultValue: []);
  }

  // --- HITUNG NOTIFIKASI BELUM DIBACA ---
  int getUnreadCount() {
    var logs = getAllNotifications();
    return logs.where((item) => item['isRead'] == false).length;
  }

  // --- TANDAI SEMUA SUDAH DIBACA (FIX ERROR TYPE) ---
  void markAllAsRead() {
    var box = Hive.box(notificationBox);
    List<dynamic> logs = List.from(box.get('logs', defaultValue: []));
    
    for (var i = 0; i < logs.length; i++) {
      // Perbaikan: Konversi ke Map agar tidak error 'Object'
      var notification = Map.from(logs[i] as Map);
      notification['isRead'] = true;
      logs[i] = notification;
    }
    
    box.put('logs', logs);
    
    // UI langsung merespon menjadi nol
    unreadCount.value = 0;
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
      'eco_step_general', 
      'Notifikasi Umum',   
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Judul cerdas: membedakan tips dan alarm sampah
    String notificationTitle = label.contains("✨") || label.contains("🌱") 
        ? "Tips Ramah Lingkungan 🍃" 
        : "Waktunya Buang Sampah! 🚛";

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      notificationTitle,
      label,
      platformChannelSpecifics,
    );

    Get.snackbar(
      notificationTitle.toUpperCase(),
      label,
      backgroundColor: Colors.white,
      icon: const Icon(Icons.eco, color: Color(0xFF6B8E23)),
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

  String hashPassword(String password) {
    var bytes = utf8.encode(password); 
    return sha256.convert(bytes).toString();
  }

  // --- FITUR: HITUNGAN SCAN PER USER ---
  void saveScanResult(String label, double confidence, String funFact) {
    var box = Hive.box(historyBox);
    var session = Hive.box(sessionBox);
    
    String currentUser = session.get('currentUser') ?? 'guest';

    box.add({
      'user': currentUser, 
      'label': label,
      'confidence': confidence,
      'funFact': funFact,
      'dateTime': DateTime.now().toString(),
    });

    // Hitungan scan dipisah per user agar tidak digabung
    int userScanCount = box.values.where((item) => item['user'] == currentUser).length;

    if (userScanCount % 5 == 0) {
      saveNotification("Hebat!", "Kamu sudah melakukan scan sebanyak $userScanCount kali! 🌱");
    }
  }

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