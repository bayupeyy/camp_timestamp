import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // Import variabel cameras
import 'preview_editor_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  String currentLocation = "Mencari Lokasi...";
  String currentTime = "";
  bool isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _requestPermissionsAndLocation();
    _startClock();
  }

  // 1. Inisialisasi Kamera
  void _initializeCamera() {
    controller = CameraController(cameras[0], ResolutionPreset.high);
    controller?.initialize().then((_) {
      if (!mounted) return;
      setState(() => isCameraReady = true);
    });
  }

  // 2. Timer untuk jam berjalan
  void _startClock() {
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) {
        setState(() {
          currentTime = DateFormat(
            'dd MMM yyyy HH:mm:ss',
          ).format(DateTime.now());
        });
      }
    });
  }

  // 3. Request Izin & Get Lokasi
  Future<void> _requestPermissionsAndLocation() async {
    await [Permission.camera, Permission.location].request();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _getAddressFromLatLng(position);
    } catch (e) {
      setState(
        () => currentLocation = "Lokasi tidak ditemukan (Tap untuk edit)",
      );
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        currentLocation =
            "${place.street}, ${place.subLocality}, ${place.locality}";
      });
    } catch (e) {
      setState(() => currentLocation = "Gagal memuat alamat");
    }
  }

  // 4. Ambil Foto
  Future<void> _takePicture() async {
    if (!controller!.value.isInitialized) return;
    final image = await controller!.takePicture();

    // Pindah ke layar Editor dengan membawa data foto, lokasi, dan waktu
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewEditorScreen(
            imagePath: image.path,
            initialLocation: currentLocation,
            initialTime: currentTime,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Stack(
        children: [
          // Viewfinder Kamera Fullscreen
          SizedBox.expand(child: CameraPreview(controller!)),

          // Overlay Info Sementara (Hanya visual UI)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                Text(
                  currentLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
