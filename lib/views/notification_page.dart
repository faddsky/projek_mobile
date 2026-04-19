import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Memanggil DatabaseService yang sudah di-inject oleh GetX
    final dbService = Get.find<DatabaseService>();
    
    // Mengambil semua riwayat notifikasi dari Hive
    final List<dynamic> notifications = dbService.getAllNotifications();

    return Scaffold(
      // Warna background sage muda banget biar aesthetic
      backgroundColor: const Color(0xFFF8FAF8), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.green[900]),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Notifikasi ✨",
          style: TextStyle(
            color: Colors.green[900], 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon imut kalau notifikasi kosong
                  Icon(Icons.mail_outline_rounded, size: 100, color: Colors.green[100]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada pesan nih, Dil...",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final DateTime dt = DateTime.parse(item['time']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Hijau pastel muda
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['title'].toString().contains("Green") 
                            ? Icons.eco_rounded 
                            : Icons.notifications_active_rounded,
                        color: const Color(0xFF6B8E23),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          item['body'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(dt),
                          style: TextStyle(color: Colors.green[200], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}