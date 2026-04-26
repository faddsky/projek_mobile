import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GameController());

    // Inisialisasi sensor dan tutorial setelah frame pertama dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initSensors(context);
      _showTutorialDialog(context, controller);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Judul Level Reaktif
        title: Obx(
          () => Text(
            "EcoGame Level ${controller.difficultyLevel.value}",
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Tombol Back dengan pembersihan manual jika perlu
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20), size: 20),
          onPressed: () {
            controller.stopTimers();
            Get.back();
          },
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/back2.jpg', 
              fit: BoxFit.cover, // Gunakan cover agar lebih penuh di berbagai rasio layar
            ),
          ),

          // 2. HUD - Stats (Score & Hearts)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skor Reaktif
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "Score: ${controller.score.value}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Nyawa (Hearts) Reaktif
                Obx(
                  () => Row(
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < controller.lives.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. HUD - Bomb Bolt Icons
          Positioned(
            top: 70,
            left: 20,
            child: Obx(
              () => Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.bolt,
                    color: i < controller.bombCount.value
                        ? Colors.orange
                        : Colors.grey.withAlpha(150),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // 4. Render Falling Items (Trash/Bombs)
          Obx(
            () => Stack(
              children: controller.fallingItems.map((item) {
                return Positioned(
                  left: Get.width / 2 + item.x - 25,
                  top: item.y,
                  child: Image.asset(
                    item.imagePath, 
                    width: 50, 
                    height: 50,
                  ),
                );
              }).toList(),
            ),
          ),

          // 5. Player Bin (Tong Sampah)
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

          // 6. Explosion Overlay (Efek Kocok HP)
          Obx(
            () => controller.isExploding.value
                ? Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.4),
                      child: const Center(
                        child: Text(
                          "BOOM!",
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
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

  // --- Dialog Tutorial ---
  void _showTutorialDialog(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "EcoStep: Cara Bermain 🌿", 
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Miringkan HP ke kiri/kanan untuk gerakkan Tong."),
            SizedBox(height: 8),
            Text("2. Tangkap sampah plastik & kertas (Poin +10)."),
            SizedBox(height: 8),
            Text("3. Hindari sampah organik (Nyawa -1)."),
            SizedBox(height: 8),
            Text("4. Tangkap BOLT untuk mengumpulkan BOM."),
            SizedBox(height: 8),
            Text("5. KOCOK HP saat punya BOM untuk ledakkan sampah organik!"),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text(
                "Mulai Main!", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}