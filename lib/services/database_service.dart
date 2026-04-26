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

    updateUnreadCount();

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

  // --- MANAJEMEN RIWAYAT NOTIFIKASI ---
  void updateUnreadCount() {
    var logs = getAllNotifications();
    unreadCount.value = logs.where((item) => item['isRead'] == false).length;
  }

  void saveNotification(String title, String body) {
    var box = Hive.box(notificationBox);
    var session = Hive.box(sessionBox);

    String currentUser = session.get('currentUser', defaultValue: 'guest');

    List<dynamic> logs = List.from(box.get('logs', defaultValue: []));
    logs.insert(0, {
      'user': currentUser,
      'title': title,
      'body': body,
      'time': DateTime.now().toString(),
      'isRead': false,
    });
    box.put('logs', logs);

    updateUnreadCount();
  }

  List<dynamic> getAllNotifications() {
    var box = Hive.box(notificationBox);
    var session = Hive.box(sessionBox);
    String currentUser = session.get('currentUser', defaultValue: 'guest');

    List<dynamic> allLogs = box.get('logs', defaultValue: []);
    return allLogs.where((item) => item['user'] == currentUser).toList();
  }

  int getUnreadCount() {
    var logs = getAllNotifications();
    return logs.where((item) => item['isRead'] == false).length;
  }

  void markAllAsRead() {
    var box = Hive.box(notificationBox);
    var session = Hive.box(sessionBox);
    String currentUser = session.get('currentUser', defaultValue: 'guest');

    List<dynamic> allLogs = List.from(box.get('logs', defaultValue: []));

    for (var i = 0; i < allLogs.length; i++) {
      var notification = Map.from(allLogs[i] as Map);
      if (notification['user'] == currentUser) {
        notification['isRead'] = true;
        allLogs[i] = notification;
      }
    }

    box.put('logs', allLogs);
    unreadCount.value = 0;
  }

  // --- GREEN TIPS HARIAN ---
  void checkAndSendGreenTip() {
    var box = Hive.box(notificationBox);
    var session = Hive.box(sessionBox);

    String currentUser = session.get('currentUser', defaultValue: 'guest');
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String userTipKey = 'tip_sent_${currentUser}_$today';

    bool hasReceivedTip = box.get(userTipKey, defaultValue: false);

    if (!hasReceivedTip) {
      List<String> tips = [
        "Mengurangi satu kantong plastik hari ini sangat berarti loh! ✨ 🌱",
        "Gunakan botol minum sendiri yuk untuk mengurangi sampah plastik! 🥤 🌱",
        "Sampah organik bisa jadi kompos yang bermanfaat bagi tanamanmu. 🌱 ✨",
        "Pilah sampahmu hari ini agar bumi tetap cantik! 🌸 🌱",
        "Hemat energi yuk! Matikan lampu yang tidak terpakai. 💡 🌱"
      ];
      String tipHariIni = (tips..shuffle()).first;

      triggerAlarm(DateFormat.jm().format(DateTime.now()), tipHariIni);
      box.put(userTipKey, true);
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
            'eco_step_alarm_high',
            'Alarm Jadwal Sampah',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint("❌ Gagal menjadwalkan alarm: $e");
    }
  }

  // --- PEMICU ALARM & OTOMATIS SIMPAN RIWAYAT ---
  Future<void> triggerAlarm(String time, String label) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'eco_step_alarm_high',
      'Alarm Jadwal Sampah',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    bool isTip = label.contains("✨") || label.contains("🌱") || label.contains("🍃");
    String title = isTip ? "Tips Ramah Lingkungan 🍃" : "Waktunya Buang Sampah! 🚛";

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      label,
      platformChannelSpecifics,
    );

    // Otomatis simpan ke riwayat saat alarm bunyi
    saveNotification(title, label);

    Get.snackbar(
      title.toUpperCase(),
      label,
      backgroundColor: Colors.white,
      icon: Icon(isTip ? Icons.lightbulb_outline : Icons.eco, color: const Color(0xFF2E7D32)),
      duration: const Duration(seconds: 5),
    );
  }

  // --- MANAJEMEN ALARM ---
  List<dynamic> getAlarmsFromActivity() {
    return Hive.box(activityBox).get('alarm_list', defaultValue: []);
  }

  void saveAlarmToActivity(Map<String, dynamic> alarmData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms.add(alarmData);
    box.put('alarm_list', currentAlarms);

    _scheduleAlarmNotification(currentAlarms.length - 1, alarmData);
    saveNotification("Jadwal Baru", "Jadwal '${alarmData['label']}' jam ${alarmData['time']} berhasil dibuat.");
  }

  void updateExistingAlarm(int index, Map<String, dynamic> newData) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());

    if (index >= 0 && index < currentAlarms.length) {
      currentAlarms[index] = newData;
      box.put('alarm_list', currentAlarms);

      _scheduleAlarmNotification(index, newData);
      saveNotification("Jadwal Diperbarui", "Jadwal '${newData['label']}' diubah ke jam ${newData['time']}.");
    }
  }

  void deleteAlarmFromActivity(int index) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    String label = currentAlarms[index]['label'];

    currentAlarms.removeAt(index);
    box.put('alarm_list', currentAlarms);
    _notificationsPlugin.cancel(index);

    saveNotification("Jadwal Dihapus", "Jadwal '$label' telah dihapus.");
  }

  void updateAlarmStatus(int index, bool status) {
    var box = Hive.box(activityBox);
    List<dynamic> currentAlarms = List.from(getAlarmsFromActivity());
    currentAlarms[index]['isActive'] = status;
    box.put('alarm_list', currentAlarms);
    _scheduleAlarmNotification(index, currentAlarms[index]);

    String msg = status ? "diaktifkan" : "dimatikan";
    saveNotification("Status Alarm", "Jadwal '${currentAlarms[index]['label']}' telah $msg.");
  }

  // --- DEBUG & AUTH ---
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

  // --- SCAN & POINTS ---
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

    int userScanCount = box.values.where((item) => item['user'] == currentUser).length;
    if (userScanCount % 5 == 0) {
      saveNotification("Pencapaian!", "Kamu sudah melakukan scan sebanyak $userScanCount kali! 🌱");
    }
  }

  // --- LOGIKA POIN & HIGH SCORE ---

  int getTotalPoints() {
    return Hive.box(profileBox).get('total_points', defaultValue: 0);
  }

  void addGamePoints(int newPoints) {
    var box = Hive.box(profileBox);
    int currentPoints = getTotalPoints();
    box.put('total_points', currentPoints + newPoints);
  }

  // FITUR HIGH SCORE: Mengambil skor tertinggi per user
  int getHighScore() {
    var box = Hive.box(profileBox);
    var session = Hive.box(sessionBox);
    String currentUser = session.get('currentUser', defaultValue: 'guest');
    return box.get('high_score_$currentUser', defaultValue: 0);
  }

  // FITUR HIGH SCORE: Mengupdate skor tertinggi jika skor baru lebih besar
  Future<void> updateHighScore(int currentScore) async {
    var box = Hive.box(profileBox);
    var session = Hive.box(sessionBox);
    String currentUser = session.get('currentUser', defaultValue: 'guest');

    int oldHighScore = getHighScore();
    if (currentScore > oldHighScore) {
      await box.put('high_score_$currentUser', currentScore);
      saveNotification("Rekor Baru! 🏆", "Selamat! Kamu mencapai skor tertinggi baru: $currentScore");
    }
  }
}