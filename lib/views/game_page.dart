import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi GameController
    final controller = Get.put(GameController());

    // Inisialisasi sensor dan tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initSensors(context);
      _showTutorialDialog(context, controller);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Teks Level diubah warnanya jadi hijau (Color 0xFF4CAF50 atau 0xFF1B5E20)
        title: Obx(
          () => Text(
            "EcoGame Level ${controller.difficultyLevel.value}",
            style: const TextStyle(
              color: Color(0xFF1B5E20), // Hijau tua yang serasi
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset('assets/images/back2.jpg', fit: BoxFit.fill),
          ),

          // Stats (Score & Hearts) - Tetap Asli
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    "Score: ${controller.score.value}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Obx(
                  () => Row(
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < controller.lives.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bomb Bolt Icons - Tetap Asli
          Positioned(
            top: 55,
            left: 20,
            child: Obx(
              () => Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.bolt,
                    color: i < controller.bombCount.value
                        ? Colors.orange
                        : Colors.grey.withAlpha(128),
                    size: 35,
                  ),
                ),
              ),
            ),
          ),

          // Render Falling Trash Items
          Obx(
            () => Stack(
              children: controller.fallingItems.map((item) {
                return Positioned(
                  left: Get.width / 2 + item.x - 25,
                  top: item.y,
                  child: Image.asset(item.imagePath, width: 50, height: 50),
                );
              }).toList(),
            ),
          ),

          // Player Bin (Tong Sampah)
          Obx(
            () => Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Transform.translate(
                  offset: Offset(controller.posX.value, 0),
                  child: Image.asset(
                    'assets/images/trash.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
          ),

          // Explosion Flash Overlay
          Obx(
            () => controller.isExploding.value
                ? Positioned.fill(
                    child: Container(
                      color: Colors.white.withAlpha(77),
                      child: const Center(
                        child: Text(
                          "BOOM!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Tutorial Dialog
  void _showTutorialDialog(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("EcoStep: Cara Bermain 🌿", textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Miringkan HP untuk gerakkan Tong."),
            Text("2. Tangkap sampah plastik & kertas."),
            Text("3. Hindari sampah organik."),
            Text("4. Tangkap BOM petir."),
            Text("5. KOCOK HP untuk ledakkan sampah organik!"),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.startGame();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Mulai Main!", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}