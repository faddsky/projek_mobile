import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Pastikan IP ini sesuai dengan IP Google Cloud kamu
  static const String baseUrl = 'http://34.66.52.247/api/data';

  // 1. Fungsi untuk AMBIL DATA (Ini yang bikin merah tadi)
  static Future<List<dynamic>> fetchData() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error Fetch: $e");
      return [];
    }
  }

  // 2. Fungsi untuk KIRIM DATA
  static Future<void> sendEcoData(String aktivitas, int langkah) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'aktivitas': aktivitas,
        'langkah': langkah,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal kirim data ke Cloud');
    }
  }
}