import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FallingItem {
  double x;
  double y;
  IconData icon;
  Color color;

  FallingItem({required this.x, required this.y, required this.icon, required this.color});
}

class EcoGamePage extends StatefulWidget {
  const EcoGamePage({super.key});

  @override
  State<EcoGamePage> createState() => _EcoGamePageState();
}

class _EcoGamePageState extends State<EcoGamePage> {
  double posX = 0.0; 
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  List<FallingItem> fallingItems = [];
  int score = 0;
  Timer? spawnTimer;
  Timer? updateTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        // Menggerakkan tong berdasarkan rotasi Gyroscope
        posX = posX - (event.y * 10);

        // Batasi agar tong tidak keluar layar
        if (posX < -150) posX = -150;
        if (posX > 150) posX = 150;
      });
    });

    startGameLoop();
  }

  void startGameLoop() {
    // Timer 1: Munculkan sampah baru
    spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;
      setState(() {
        fallingItems.add(FallingItem(
          x: _random.nextDouble() * 250 - 125, 
          y: -50, 
          icon: _random.nextBool() ? Icons.apple : Icons.recycling,
          color: Colors.green,
        ));
      });
    });

    // Timer 2: Update posisi jatuh & deteksi tabrakan
    updateTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        for (int i = fallingItems.length - 1; i >= 0; i--) {
          fallingItems[i].y += 7;

          // Logika Tabrakan: Jika sampah mengenai koordinat tong
          if (fallingItems[i].y > 450 && 
              fallingItems[i].y < 520 && 
              (fallingItems[i].x - posX).abs() < 40) {
            score++;
            fallingItems.removeAt(i);
          } 
          else if (fallingItems[i].y > 600) {
            fallingItems.removeAt(i);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    spawnTimer?.cancel();
    updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Perbaikan: Hapus 'const' di depan TextStyle jika menggunakan green[900]
    final scoreStyle = TextStyle(
      fontSize: 28, 
      fontWeight: FontWeight.bold, 
      color: Colors.green[900], // Tidak akan error lagi
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco-Catch Game"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(color: Colors.lightBlue[50]),

          Positioned(
            top: 40, left: 0, right: 0,
            child: Center(child: Text("Skor: $score", style: scoreStyle)),
          ),

          // Render sampah yang sedang jatuh
          ...fallingItems.map((item) {
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + item.x - 20,
              top: item.y,
              child: Icon(item.icon, size: 40, color: item.color),
            );
          }),

          // Tong Sampah (Digerakkan Gyroscope)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Transform.translate(
                offset: Offset(posX, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.delete, size: 80, color: Colors.green),
                    Text("TONG ECO", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}