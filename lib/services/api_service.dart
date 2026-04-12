import 'dart:convert';
import 'dart:io';

class ApiService {
  static Future<Map<String, dynamic>> getWorldTime(String timezone) async {
    // Pakai TimeAPI.io karena lebih stabil untuk request via HP
    final String url = "https://timeapi.io/api/Time/current/zone?timeZone=$timezone";
    
    final client = HttpClient();
    // Tambahkan timeout di sisi client
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      // Kita buat request manual untuk kontrol header yang lebih dalam
      final request = await client.getUrl(Uri.parse(url));
      
      // Tambahkan headers standar browser mobile
      request.headers.set('Accept', 'application/json');
      request.headers.set('User-Agent', 'Mozilla/5.0 (Android 10; Mobile; rv:115.0) Gecko/115.0 Firefox/115.0');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);

        // TimeAPI.io menggunakan field 'dateTime'
        DateTime parseTime = DateTime.parse(data['dateTime']);

        List<String> days = [
          "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu",
        ];
        
        // DateTime.weekday: 1 (Senin) - 7 (Minggu)
        String dayName = days[parseTime.weekday % 7];

        return {
          'time': "${parseTime.hour.toString().padLeft(2, '0')}:${parseTime.minute.toString().padLeft(2, '0')}",
          'date': "$dayName, ${parseTime.day}-${parseTime.month}-${parseTime.year}",
          'dayOfWeek': dayName,
        };
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Eror Full API: $e");
      // Kita rethrow supaya ConversionPage tahu kalau ini eror dan bisa nampilin pesan eror di UI
      rethrow; 
    } finally {
      client.close(); // Tutup client untuk hemat memori
    }
  }
}