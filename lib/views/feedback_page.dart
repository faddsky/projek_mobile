import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kesan & Saran TPM"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.green[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bagaimana kesanmu selama kuliah TPM?", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _buildFeedbackCard(
              "Kesan", 
              "Kuliah TPM sangat menantang! Belajar Flutter dan integrasi sensor bikin aku makin paham gimana cara kerja aplikasi mobile yang sesungguhnya.",
              Icons.auto_awesome
            ),
            
            const SizedBox(height: 20),
            
            _buildFeedbackCard(
              "Saran", 
              "Semoga ke depannya materi tentang integrasi AI di Flutter bisa lebih diperbanyak lagi karena seru banget!",
              Icons.lightbulb_outline
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6B8E23)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 25),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}