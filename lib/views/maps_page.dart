import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final MapController _mapController = MapController();
  LatLng _myLocation = const LatLng(-7.7956, 110.3695); // Default Jogja
  List<Map<String, dynamic>> _tpsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // Fungsi inisialisasi: Ambil GPS dulu, baru tembak API
  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();
    await _fetchTPSData(_myLocation.latitude, _myLocation.longitude);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("GPS tidak aktif.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Izin lokasi ditolak.");
        return;
      }
    }

    // Menggunakan Best Accuracy agar posisi tepat
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    if (mounted) {
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_myLocation, 15.0);
    }
  }

  // AMBIL DATA DARI API GRATIS (Overpass OSM)
  Future<void> _fetchTPSData(double lat, double lng) async {
    // Radius 20km (20000m) untuk memastikan data ketemu
    final query =
        '[out:json];node["amenity"~"waste_disposal|waste_transfer_station"](around:20000,$lat,$lng);out body;';

    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=$query",
    );

    try {
      debugPrint("Sedang mengambil data TPS untuk lokasi: $lat, $lng...");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> tempItems = [];

        for (var element in data['elements']) {
          tempItems.add({
            'nama': element['tags']['name'] ?? 'TPS Terdekat',
            'latlng': LatLng(element['lat'], element['lon']),
            'info': element['tags']['operator'] ?? 'Fasilitas Umum',
          });
        }

        debugPrint("Berhasil menemukan ${tempItems.length} TPS.");

        if (mounted) {
          setState(() {
            _tpsList = tempItems;
          });
        }
      } else {
        debugPrint("Gagal ke server: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error API: $e");
      _showError("Gagal memuat data TPS. Cek koneksi internet.");
    }
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final Uri googleUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    try {
      if (!await launchUrl(googleUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $googleUrl';
      }
    } catch (e) {
      _showError("Gagal membuka navigasi.");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _calculateDistance(LatLng dest) {
    double distanceInMeters = Geolocator.distanceBetween(
      _myLocation.latitude,
      _myLocation.longitude,
      dest.latitude,
      dest.longitude,
    );
    return distanceInMeters < 1000
        ? "${distanceInMeters.toStringAsFixed(0)} m"
        : "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "EcoStep LBS - Lokasi TPS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _initLocation),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _myLocation, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.melania.ecostep',
              ),
              MarkerLayer(
                markers: [
                  // Marker Lokasi User (Biru)
                  Marker(
                    point: _myLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 45,
                    ),
                  ),
                  // Marker TPS (Merah)
                  ..._tpsList.map(
                    (tps) => Marker(
                      point: tps['latlng'],
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showTPSDetail(tps),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.green)),

          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5),
                ],
              ),
              child: Text(
                _isLoading
                    ? "Mencari TPS..."
                    : "Ditemukan ${_tpsList.length} TPS",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTPSDetail(Map<String, dynamic> tps) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tps['nama'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _calculateDistance(tps['latlng']),
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(tps['info'], style: const TextStyle(color: Colors.grey)),
              const Divider(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchNavigation(
                      tps['latlng'].latitude,
                      tps['latlng'].longitude,
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text("PETUNJUK JALAN"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
