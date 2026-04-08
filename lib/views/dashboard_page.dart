import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header User
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Halo, Dila!", style: TextStyle(fontSize: 16)),
                      Text("Selamatkan Bumi Hari Ini 🌿", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=26'), // Dummy photo
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Card Pedometer (Accelerometer)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8DAA91), Color(0xFF6B8E23)]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text("Langkah Kakimu", style: TextStyle(color: Colors.white, fontSize: 16)),
                    Obx(() => Text("${controller.stepCount.value}", 
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Obx(() => Text("🌱 Kamu menghemat ${controller.carbonSaved.value.toStringAsFixed(2)}g Karbon", 
                      style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Fitur AI Scanner
              const Text("Eco AI Scanner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              InkWell(
                onTap: () => controller.scanWaste(),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 50, color: Colors.green[300]),
                      const SizedBox(height: 10),
                      const Text("Klik untuk Scan Sampah", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}