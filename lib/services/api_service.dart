import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<Map<String, dynamic>> getWorldTime(String timezone) async {
    // Kita pakai WorldTimeAPI karena lebih stabil untuk region kita
    // URL di .env pastikan: http://worldtimeapi.org/api
    final String baseUrl =
        dotenv.env['TIME_API_URL'] ?? 'http://worldtimeapi.org/api';

    try {
      // Endpoint WorldTimeAPI itu: /timezone/{zone}
      final response = await http
          .get(
            Uri.parse("$baseUrl/timezone/$timezone"),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'EcoStepApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Karena format WorldTimeAPI beda, kita bungkus lagi biar sama
        // dengan variabel yang ada di Page kamu (remoteTime & remoteDate)
        DateTime parseTime = DateTime.parse(data['datetime']);

        return {
          'time':
              "${parseTime.hour.toString().padLeft(2, '0')}:${parseTime.minute.toString().padLeft(2, '0')}",
          'date':
              "${data['day_of_week']}, ${parseTime.day}-${parseTime.month}-${parseTime.year}",
          'dayOfWeek': _getDayName(data['day_of_week']),
        };
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error Detail: $e");
      rethrow;
    }
  }

  // Helper untuk ubah angka hari jadi nama hari
  static String _getDayName(int day) {
    const days = [
      "Minggu",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
    ];
    return days[day % 7];
  }
}
