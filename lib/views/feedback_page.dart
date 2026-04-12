import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan warna background yang konsisten dengan HomeTab
      backgroundColor: const Color(0xFFF8FAF8), 
      appBar: AppBar(
        title: const Text(
          "Kesan & Saran TPM 📝", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4A6741),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
              "Bagaimana kesanmu selama kuliah TPM?", 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF2E7D32)
              )
            ),
            const SizedBox(height: 25),
            
            // Konten Kesan
            _buildFeedbackCard(
              "Kesan Belajar", 
              "Kuliah TPM sangat menantang! Belajar Flutter dan integrasi sensor bikin aku makin paham gimana cara kerja aplikasi mobile yang sesungguhnya.",
              Icons.auto_awesome_rounded,
              const Color(0xFFE8F5E9), // Light Green accent
            ),
            
            const SizedBox(height: 20),
            
            // Konten Saran
            _buildFeedbackCard(
              "Saran Kedepan", 
              "Semoga ke depannya materi tentang integrasi AI di Flutter bisa lebih diperbanyak lagi karena seru banget!",
              Icons.lightbulb_rounded,
              const Color(0xFFFFF3E0), // Light Orange accent
            ),

            const SizedBox(height: 30),

            // Tambahan: Quote atau Penutup Kecil agar lebih manis
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: const [
                    Icon(Icons.eco_rounded, color: Color(0xFF6B8E23)),
                    SizedBox(height: 8),
                    Text(
                      "Terima kasih telah berproses bersama!",
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String title, String content, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // Sudut lebih melengkung agar imut
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ikon dengan background lingkaran kecil
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6B8E23), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Color(0xFF4A6741)
                )
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
          ),
          Text(
            content, 
            style: const TextStyle(
              height: 1.6, 
              fontSize: 14, 
              color: Colors.black87
            )
          ),
        ],
      ),
    );
  }
}