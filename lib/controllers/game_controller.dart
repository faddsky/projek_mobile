import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:projek_mobile/services/database_service.dart';

enum TrashType { recyclable, nonRecyclable, bomb, explosion }

class FallingItem {
  double x, y;
  String imagePath;
  TrashType type;
  FallingItem({required this.x, required this.y, required this.imagePath, required this.type});
}

class GameController extends GetxController {
  // --- Variabel Reaktif ---
  var posX = 0.0.obs;
  var score = 0.obs;
  var lives = 3.obs;
  var bombCount = 0.obs;
  var difficultyLevel = 1.obs;
  var isGameOver = false.obs;
  var isGameStarted = false.obs;
  var isExploding = false.obs;
  var fallingItems = <FallingItem>[].obs;

  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  Timer? spawnTimer, updateTimer, difficultyTimer;
  final Random _random = Random();

  // --- Inisialisasi Sensor ---
  void initSensors(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double limit = (screenWidth / 2) - 50;

    _accelSubscription = accelerometerEventStream().listen((event) {
      if (isGameOver.value || !isGameStarted.value || isExploding.value) return;
      
      // Sensitivitas gerak tong (Tilt)
      double targetX = -event.x * 55;
      posX.value = (posX.value * 0.75) + (targetX * 0.25); // Smoothing
      posX.value = posX.value.clamp(-limit, limit);
    });

    _gyroSubscription = gyroscopeEventStream().listen((event) {
      if (!isGameStarted.value || isGameOver.value || bombCount.value <= 0 || isExploding.value) return;
      
      // Deteksi kocok (Shake) untuk bom
      if ((event.x.abs() + event.y.abs() + event.z.abs()) > 15) {
        handleShakeExplosion();
      }
    });
  }

  // --- Logika Game Loop ---
  void startGame() {
    isGameStarted.value = true;
    isGameOver.value = false;
    _startSpawnTimer();
    
    // Update fisika setiap 30ms
    updateTimer = Timer.periodic(const Duration(milliseconds: 30), (_) => _updatePhysics());
    
    // Naikkan kesulitan setiap 30 detik
    difficultyTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isGameOver.value) return;
      difficultyLevel.value++;
      spawnBomb();
      _startSpawnTimer(); // Refresh spawn speed
    });
  }

  void _startSpawnTimer() {
    spawnTimer?.cancel();
    // Semakin tinggi level, semakin cepat spawn (minimal 400ms)
    int spawnSpeed = max(400, 1400 - (difficultyLevel.value * 150));
    spawnTimer = Timer.periodic(Duration(milliseconds: spawnSpeed), (_) => spawnTrash());
  }

  void spawnTrash() {
    bool isRecyclable = _random.nextDouble() > 0.4;
    
    List<String> recyclableList = [
      'bottle.png', 'cardboard.png', 'paper.png', 
      'board.png', 'book.png', 'can.png', 'botle2.png'
    ];
    
    List<String> nonRecyclableList = [
      'apple.png', 'banana.png', 'cake.png', 
      'strawberry.png', 'apel2.png', 'carrot.png', 'banana2.png'
    ];

    String path = isRecyclable 
      ? recyclableList[_random.nextInt(recyclableList.length)] 
      : nonRecyclableList[_random.nextInt(nonRecyclableList.length)];

    fallingItems.add(FallingItem(
      imagePath: 'assets/images/$path',
      x: _random.nextDouble() * 260 - 130, 
      y: -50,
      type: isRecyclable ? TrashType.recyclable : TrashType.nonRecyclable,
    ));
  }

  void spawnBomb() {
    fallingItems.add(FallingItem(
      imagePath: 'assets/images/bomb.png',
      x: _random.nextDouble() * 260 - 130,
      y: -50,
      type: TrashType.bomb,
    ));
  }

  void _updatePhysics() {
    if (isExploding.value || isGameOver.value) return;

    for (int i = fallingItems.length - 1; i >= 0; i--) {
      // Kecepatan jatuh bertambah sesuai level
      fallingItems[i].y += (6 + (difficultyLevel.value * 0.8));

      // Deteksi tabrakan dengan tong (Posisi Y antara 590-680)
      if (fallingItems[i].y > 590 && 
          fallingItems[i].y < 680 && 
          (fallingItems[i].x - posX.value).abs() < 40) {
        _handleCollision(i);
      } else if (fallingItems[i].y > 850) {
        fallingItems.removeAt(i);
      }
    }
    fallingItems.refresh();
  }

  void _handleCollision(int index) {
    var item = fallingItems[index];
    if (item.type == TrashType.bomb) {
      if (bombCount.value < 3) bombCount.value++;
    } else if (item.type == TrashType.recyclable) {
      score.value += 10;
    } else if (item.type == TrashType.nonRecyclable) {
      lives.value--;
      if (lives.value <= 0) handleGameOver();
    }
    fallingItems.removeAt(index);
  }

  void handleShakeExplosion() async {
    isExploding.value = true;
    bombCount.value--;
    
    // Ubah semua sampah non-recyclable di layar jadi ledakan
    for (var item in fallingItems) {
      if (item.type == TrashType.nonRecyclable) {
        item.imagePath = 'assets/images/explosion.png';
        item.type = TrashType.explosion;
      }
    }
    fallingItems.refresh();

    await Future.delayed(const Duration(seconds: 1));
    fallingItems.removeWhere((item) => item.type == TrashType.explosion);
    isExploding.value = false;
  }

  // --- Game Over & Database Sync ---
  void handleGameOver() async {
    isGameOver.value = true;
    stopTimers();

    final db = Get.find<DatabaseService>();
    
    // 1. Simpan poin total
    db.addGamePoints(score.value);
    
    // 2. Cek dan update High Score
    await db.updateHighScore(score.value);
    int currentHigh = db.getHighScore();

    // 3. Munculkan Dialog Hasil
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("GAME OVER! 🗑️", 
          textAlign: TextAlign.center, 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Kerja bagus! Terus jaga lingkungan ya."),
            const SizedBox(height: 20),
            Text("Skor Kamu: ${score.value}", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            Text("Skor Tertinggi: $currentHigh", 
              style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)
            ),
            if (score.value >= currentHigh && score.value > 0)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("REKOR BARU! 🎉", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        actions: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Get.back(); // Tutup dialog
                      resetGame();
                    },
                    child: const Text("Main Lagi", style: TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.back(); // Tutup dialog
                    Get.back(); // Keluar ke halaman sebelumnya
                  },
                  child: const Text("Keluar"),
                ),
              ],
            ),
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  void resetGame() {
    score.value = 0;
    lives.value = 3;
    bombCount.value = 0;
    difficultyLevel.value = 1;
    fallingItems.clear();
    isGameOver.value = false;
    isExploding.value = false;
    startGame();
  }

  void stopTimers() {
    spawnTimer?.cancel();
    updateTimer?.cancel();
    difficultyTimer?.cancel();
  }

  @override
  void onClose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    stopTimers();
    super.onClose();
  }
}