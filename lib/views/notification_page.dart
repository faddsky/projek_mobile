import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Get.find<DatabaseService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      dbService.markAllAsRead();
    });

    final List<dynamic> notifications = dbService.getAllNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar yang lebih ringkas dan proporsional
          SliverAppBar(
            expandedHeight: 90.0, // Diperkecil agar judul tidak terlalu ke bawah
            floating: true,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            backgroundColor: const Color(0xFFF8FAF8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20), size: 20),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              "Notifikasi",
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),

          // Konten Utama
          notifications.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false, // Menghindari overflow
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = notifications[index];
                        final DateTime dt = DateTime.parse(item['time']);
                        return _buildNotificationCard(item, dt);
                      },
                      childCount: notifications.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center( // Memastikan benar-benar di tengah layar
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 70,
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Belum ada pesan",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Kotak masukmu masih kosong untuk saat ini.",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map item, DateTime dt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),
          title: Text(
            item['title'] ?? "Pemberitahuan",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            DateFormat('dd MMM, HH:mm').format(dt),
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['body'] ?? "",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}