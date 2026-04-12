import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import package dotenv

class AirService {
  // Mengambil API Key dari file .env
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? ""; 

  Future<Map<String, dynamic>> getAirData() async {
    try {
      // Mengambil lokasi terkini perangkat
      Position pos = await _getGeoLocation();

      // URL API OpenWeather untuk Air Pollution
      final url = "https://api.openweathermap.org/data/2.5/air_pollution?lat=${pos.latitude}&lon=${pos.longitude}&appid=$apiKey";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw "API Key belum aktif atau salah, tunggu sekitar 2 jam ya!";
      } else {
        throw "Gagal mengambil data udara (Status: ${response.statusCode})";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // --- FUNGSI: Mendapatkan Nama Kota ---
  Future<String> getLocationName(double lat, double lon) async {
    try {
      // Menggunakan API Geocoding bawaan OpenWeather
      final url = "https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Mengambil nama kota dan kode negara
          return "${data[0]['name']}, ${data[0]['country']}";
        }
      }
      return "Lokasi tidak dikenal";
    } catch (e) {
      return "Gagal memuat nama lokasi";
    }
  }

  // --- FUNGSI: Logika Geolocation ---
  Future<Position> _getGeoLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw "Izin lokasi ditolak oleh pengguna";
      }
    }

    try {
      if (!serviceEnabled || permission == LocationPermission.deniedForever) {
        return _getDefaultLocation();
      }

      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) return lastPos;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, 
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      return _getDefaultLocation();
    }
  }

  // --- FUNGSI: Default Lokasi (Jakarta) ---
  Position _getDefaultLocation() {
    return Position(
      latitude: -6.175392, 
      longitude: 106.827153,
      timestamp: DateTime.now(),
      accuracy: 0, 
      altitude: 0, 
      altitudeAccuracy: 0,
      heading: 0, 
      headingAccuracy: 0,
      speed: 0, 
      speedAccuracy: 0,
    );
  }
}