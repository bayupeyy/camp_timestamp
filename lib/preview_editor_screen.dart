import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img; // Library manipulasi gambar
import 'package:gal/gal.dart'; // Library save ke gallery
import 'package:path_provider/path_provider.dart';

class PreviewEditorScreen extends StatefulWidget {
  final String imagePath;
  final String initialLocation;
  final String initialTime;

  const PreviewEditorScreen({
    super.key,
    required this.imagePath,
    required this.initialLocation,
    required this.initialTime,
  });

  @override
  State<PreviewEditorScreen> createState() => _PreviewEditorScreenState();
}

class _PreviewEditorScreenState extends State<PreviewEditorScreen> {
  late TextEditingController locationController;
  late TextEditingController timeController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Isi form edit dengan data dari sensor otomatis
    locationController = TextEditingController(text: widget.initialLocation);
    timeController = TextEditingController(text: widget.initialTime);
  }

  // Fungsi Logika Watermark ("Membakar" teks ke gambar)
  Future<void> _processAndSaveImage() async {
    setState(() => isSaving = true);

    try {
      // 1. Baca file gambar asli
      final File originalFile = File(widget.imagePath);
      final List<int> bytes = await originalFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(
        Uint8List.fromList(bytes),
      );

      if (originalImage != null) {
        // 2. Siapkan Teks dari Input Manual Pengguna
        String line1 = timeController.text;
        String line2 = locationController.text;

        // 3. Tentukan Posisi & Font
        // Catatan: img.arial48 adalah font bitmap bawaan sederhana.
        // Untuk font custom .ttf butuh load file font terpisah.

        // Gambar background semi-transparan untuk teks (opsional agar terbaca)
        int bgHeight = 120;
        int yPos = originalImage.height - bgHeight;

        // Loop pixel untuk membuat kotak hitam transparan di bawah
        for (var y = yPos; y < originalImage.height; y++) {
          for (var x = 0; x < originalImage.width; x++) {
            var pixel = originalImage.getPixel(x, y);
            // Logika darken/alpha blending sederhana manual atau lewati step ini
            // Agar simpel, kita langsung gambar teks saja dengan warna kontras
          }
        }

        // 4. Tulis Teks ke Gambar (Watermarking)
        img.drawString(
          originalImage,
          font: img.arial48, // Ukuran font
          x: 50,
          y: originalImage.height - 150,
          line1,
          color: img.ColorRgb8(255, 255, 0), // Warna Kuning
        );

        img.drawString(
          originalImage,
          font: img.arial24,
          x: 50,
          y: originalImage.height - 90,
          line2,
          color: img.ColorRgb8(255, 255, 255), // Warna Putih
        );

        // 5. Simpan file baru
        final directory = await getApplicationDocumentsDirectory();
        final String newPath =
            '${directory.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File newFile = File(newPath)
          ..writeAsBytesSync(img.encodeJpg(originalImage));

        // 6. Simpan ke Galeri HP
        await Gal.putImage(newPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto Tersimpan di Galeri!")),
          );
          Navigator.pop(context); // Kembali ke kamera
        }
      }
    } catch (e) {
      print("Error saving: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  // Dialog untuk Edit Manual
  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Info Watermark"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Waktu"),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Lokasi"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Refresh UI Preview
              Navigator.pop(ctx);
            },
            child: const Text("Update Preview"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview & Edit")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Gambar Preview
                Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),

                // UI Mockup Watermark (Apa yang user lihat sebelum di-save)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black45, // Background semi transparan
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeController.text,
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          locationController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _showEditDialog, // FITUR EDIT MANUAL
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Info"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : _processAndSaveImage,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text("Simpan"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
