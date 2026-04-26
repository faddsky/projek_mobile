import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), 
      appBar: AppBar(
        title: const Text(
          "Kesan & Saran TPM", 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Kesan dan Saran",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // KESAN BARU
              _buildFeedbackCard(
                "Kesan Belajar", 
                "Seru banget bisa eksplorasi Flutter lebih jauh! Walaupun sempat pusing pas debugging logika dan nyusun layout biar aesthetic, tapi puas banget pas lihat hasilnya sesuai ekspektasi. Materi TPM bener-bener ngebuka insight baru buat bikin aplikasi yang lebih interaktif.",
                Icons.emoji_objects_rounded,
                const Color(0xFFE8F5E9),
              ),
              
              const SizedBox(height: 20),
              
              // SARAN BARU
              _buildFeedbackCard(
                "Saran Kedepan", 
                "Untuk pengembangan mata kuliah ke depannya, mungkin bisa diberikan lebih banyak studi kasus tentang optimalisasi performa aplikasi saat menggunakan banyak sensor secara bersamaan. Selain itu, sesi sharing session tentang publikasi aplikasi ke Play Store atau App Store juga akan sangat bermanfaat bagi mahasiswa.",
                Icons.tips_and_updates_rounded,
                const Color(0xFFFFF3E0),
              ),

              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          )
                        ]
                      ),
                      child: const Icon(Icons.eco_rounded, color: Color(0xFF8BC34A), size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "EcoStep 2026",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFBDBDBD),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String title, String content, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title, 
                style: const TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 17,
                  color: Color(0xFF1B5E20)
                )
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            width: 40,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 16),
          Text(
            content, 
            style: TextStyle(
              height: 1.7, 
              fontSize: 14, 
              color: Colors.grey[800],
              letterSpacing: 0.2,
            )
          ),
        ],
      ),
    );
  }
}