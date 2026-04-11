import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:projek_mobile/services/database_service.dart';

enum TrashType { recyclable, nonRecyclable }

class FallingItem {
  double x, y;
  String imagePath;
  TrashType type;
  FallingItem({
    required this.x,
    required this.y,
    required this.imagePath,
    required this.type,
  });
}

class EcoGamePage extends StatefulWidget {
  const EcoGamePage({super.key});
  @override
  State<EcoGamePage> createState() => _EcoGamePageState();
}

class _EcoGamePageState extends State<EcoGamePage> {
  double posX = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  List<FallingItem> fallingItems = [];
  int score = 0;
  int lives = 3;
  int difficultyLevel = 1;
  bool isGameOver = false;

  Timer? spawnTimer, updateTimer, difficultyTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initAccelerometer();
    startGame();
  }

  void _initAccelerometer() {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!mounted || isGameOver) return;
      double screenWidth = MediaQuery.of(context).size.width;
      double limit = (screenWidth / 2) - 50;
      setState(() {
        double targetX = -event.x * 55;
        posX = (posX * 0.75) + (targetX * 0.25);
        posX = posX.clamp(-limit, limit);
      });
    });
  }

  void startGame() {
    _startSpawnTimer();
    updateTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || isGameOver) return;
      _updatePhysics();
    });
    difficultyTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || isGameOver) return;
      setState(() {
        difficultyLevel++;
        _startSpawnTimer();
      });
    });
  }

  void _startSpawnTimer() {
    spawnTimer?.cancel();
    int spawnSpeed = max(400, 1400 - (difficultyLevel * 150));
    spawnTimer = Timer.periodic(Duration(milliseconds: spawnSpeed), (timer) {
      if (!mounted || isGameOver) return;
      _spawnTrash();
    });
  }

  void _spawnTrash() {
    setState(() {
      bool isRecyclable = _random.nextDouble() > 0.4;
      String path = isRecyclable
          ? ['bottle.png', 'cardboard.png', 'paper.png'][_random.nextInt(3)]
          : ['apple.png', 'banana.png', 'bread.png'][_random.nextInt(3)];

      double screenWidth = MediaQuery.of(context).size.width;
      fallingItems.add(
        FallingItem(
          imagePath: 'assets/images/$path',
          x: _random.nextDouble() * (screenWidth - 80) - (screenWidth / 2 - 40),
          y: -50,
          type: isRecyclable ? TrashType.recyclable : TrashType.nonRecyclable,
        ),
      );
    });
  }

  void _updatePhysics() {
    setState(() {
      for (int i = fallingItems.length - 1; i >= 0; i--) {
        fallingItems[i].y += (6 + (difficultyLevel * 0.8));

        if (fallingItems[i].y > 470 &&
            fallingItems[i].y < 550 &&
            (fallingItems[i].x - posX).abs() < 55) {
          if (fallingItems[i].type == TrashType.recyclable) {
            score += 10;
          } else {
            lives--;
            if (lives <= 0) _handleGameOver();
          }
          fallingItems.removeAt(i);
        } else if (fallingItems[i].y > 850) {
          fallingItems.removeAt(i);
        }
      }
    });
  }

  void _handleGameOver() {
    isGameOver = true;
    final dbService = Get.find<DatabaseService>();
    int oldHighScore = dbService.getTotalPoints();

    if (score > oldHighScore) {
      dbService.addGamePoints(score);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: ScaleTransition(
            scale: anim1,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const Text(
                    "GAME OVER",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const Divider(),
                  Text(
                    "Skor Kamu: $score",
                    style: const TextStyle(fontSize: 22),
                  ),
                  Text(
                    score > oldHighScore
                        ? "🔥 REKOR BARU!"
                        : "High Score: $oldHighScore",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            "Main Lagi",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.offAllNamed('/home'),
                          child: const Text("Keluar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      score = 0;
      lives = 3;
      difficultyLevel = 1;
      fallingItems.clear();
      isGameOver = false;
      startGame();
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    spawnTimer?.cancel();
    updateTimer?.cancel();
    difficultyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50), // Navbar Hijau Solid
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "LEVEL $difficultyLevel",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 40), // Spacer biar level tetap agak ke tengah
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Background (BoxFit.fill agar tanah tidak terpotong)
          Positioned.fill(
            child: Image.asset('assets/images/back2.jpg', fit: BoxFit.fill),
          ),

          // 2. HATI (LIVES) - Di bawah Navbar, warna Merah
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < lives ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red, // Warna merah sesuai request
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          // 3. Score (Teks kecil di pojok kiri atas area main)
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              "Score: $score",
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          // 4. Falling Items
          ...fallingItems.map(
            (item) => Positioned(
              left: MediaQuery.of(context).size.width / 2 + item.x - 25,
              top: item.y,
              child: Image.asset(item.imagePath, width: 45, height: 45),
            ),
          ),

          // 5. Tong Sampah (Di atas tanah rumput)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 65,
              ), // Tinggi tong di atas tanah
              child: Transform.translate(
                offset: Offset(posX, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/trash.png',
                      width: 95,
                      height: 95,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "RECYCLE ONLY",
                        style: TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
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
