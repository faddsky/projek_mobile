import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AirService {
  final String apiKey = "867f707f15e87a3536769996d9348d42"; 

  Future<Map<String, dynamic>> getAirData() async {
    try {
      // 1. Ambil Lokasi
      Position pos = await _getGeoLocation();

      // 2. Tembak API
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

    // Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('GPS kamu mati, nyalain dulu ya! 📍');
    }

    // Cek Izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak nih 😅');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen, cek pengaturan HP ya!');
    }

    // PERBAIKAN: Gunakan getCurrentPosition dengan settings agar tidak loading selamanya
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // Akurasi rendah cukup buat polusi & lebih cepat
        timeLimit: Duration(seconds: 15), // Kalau 15 detik gak dapet, lapor error
      ),
    );
  }
}