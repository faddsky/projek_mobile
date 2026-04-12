import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AirService {
  final String apiKey = "867f707f15e87a3536769996d9348d42"; 

  Future<Map<String, dynamic>> getAirData() async {
    try {
      Position pos = await _getGeoLocation();

      final url = "https://api.openweathermap.org/data/2.5/air_pollution?lat=${pos.latitude}&lon=${pos.longitude}&appid=$apiKey";
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw "Gagal ambil data udara";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Position> _getGeoLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek Layanan & Izin dasar
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      // Jika izin ditolak permanen atau GPS mati, jangan paksa, langsung ke 'catch'
      if (!serviceEnabled || permission == LocationPermission.deniedForever) {
        throw "GPS_OFF";
      }

      // 2. Coba ambil lokasi terakhir (Instan)
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) return lastPos;

      // 3. Cari posisi baru dengan batas waktu singkat (5 detik saja)
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, 
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // --- LOGIKA PENYELAMAT ---
      // Jika GPS gagal dalam 5 detik, gunakan koordinat Jakarta (Monas) 
      // agar aplikasi Dila tetap jalan dan kartu udaranya muncul.
      return Position(
        latitude: -6.175392, 
        longitude: 106.827153,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, 
        speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
      );
    }
  }
}