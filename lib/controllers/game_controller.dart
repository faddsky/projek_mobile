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
  // Variabel Reaktif (OBS)
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

  void initSensors(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double limit = (screenWidth / 2) - 50;

    _accelSubscription = accelerometerEvents.listen((event) {
      if (isGameOver.value || !isGameStarted.value || isExploding.value) return;
      double targetX = -event.x * 55;
      posX.value = (posX.value * 0.75) + (targetX * 0.25);
      posX.value = posX.value.clamp(-limit, limit);
    });

    _gyroSubscription = gyroscopeEvents.listen((event) {
      if (!isGameStarted.value || isGameOver.value || bombCount.value <= 0 || isExploding.value) return;
      // Logika Kocok
      if ((event.x.abs() + event.y.abs() + event.z.abs()) > 15) {
        handleShakeExplosion();
      }
    });
  }

  void startGame() {
    isGameStarted.value = true;
    _startSpawnTimer();
    
    updateTimer = Timer.periodic(const Duration(milliseconds: 30), (_) => _updatePhysics());
    
    difficultyTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isGameOver.value) return;
      difficultyLevel.value++;
      spawnBomb();
      _startSpawnTimer();
    });
  }

  void _startSpawnTimer() {
    spawnTimer?.cancel();
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
      x: _random.nextDouble() * 260 - 130, // Posisi X acak
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
    if (isExploding.value) return;

    for (int i = fallingItems.length - 1; i >= 0; i--) {
      fallingItems[i].y += (6 + (difficultyLevel.value * 0.8));

      // Deteksi tabrakan mepet
      if (fallingItems[i].y > 590 && 
          fallingItems[i].y < 680 && 
          (fallingItems[i].x - posX.value).abs() < 30) {
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

  void handleGameOver() {
    isGameOver.value = true;
    stopTimers();
    Get.find<DatabaseService>().addGamePoints(score.value);
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