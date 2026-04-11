import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;
  Position? _currentPosition;

  // Data Simulasi Lokasi TPS (Nanti bisa kamu ambil dari Database/API)
  final List<Marker> _tpsMarkers = [
    const Marker(
      markerId: MarkerId('tps_1'),
      position: LatLng(-7.942, 110.323), // Contoh koordinat Bantul
      infoWindow: InfoWindow(title: 'TPS Depok', snippet: 'Buka 24 Jam'),
    ),
    const Marker(
      markerId: MarkerId('tps_2'),
      position: LatLng(-7.955, 110.335),
      infoWindow: InfoWindow(
        title: 'TPS 3R Murtigading',
        snippet: 'Pengolahan Sampah',
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Panggil fungsi LBS saat buka halaman
  }

  // Fungsi Inti LBS: Ambil Lokasi User
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Ambil posisi sekarang
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    // Geser kamera peta ke lokasi user
    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TPS Terdekat (LBS)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-7.7956, 110.3695), // Default Yogyakarta
              zoom: 14,
            ),
            markers: Set<Marker>.of(_tpsMarkers),
            myLocationEnabled: true, // Nampilin titik biru lokasi user
            myLocationButtonEnabled: true,
          ),

          // Panel Info Kecil di bawah
          if (_currentPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    const BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Lokasi kamu terdeteksi. Silakan pilih TPS terdekat pada peta.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
