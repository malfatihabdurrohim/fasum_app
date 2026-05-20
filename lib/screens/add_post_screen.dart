import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shimmer/shimmer.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _Latitude;
  double? _Longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;
  List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Rusak',
    'Pipa Bocor',
    'Vandalisme',
    'Banjir',
    'Lainnya',
  ];

void _showCategorySelectionDialog() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return ListView(
        shrinkWrap: true,
        children: categories.map((category) {
          return ListTile(
            title: Text(category),
            onTap: () {
              setState(() {
                _aiCategory = category; // Ganti AI category dengan pilihan user
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      );
    }
  );
}

@override
void dispose() {
  _descriptionController.dispose();
  super.dispose();
}

Future<void> _pickImage(ImageSource source) async {
  try {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _aiCategory = null;
        _aiDescription = null;
        _descriptionController.clear();
      });
      await _compressAndEncodeImage();
      await _generateDescriptionWithAI();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }
}

Future <void> _compressAndEncodeImage() async {
  if (_image == null) return;
  try {
    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 50,
    );
    if (compressedImage != null) return;
      setState(() {
        _base64Image = base64Encode(compressedImage!);
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
    }
  }
}

Future<void> _generateDescriptionWithAI() async {
  if (_image == null) return;
  setState(() => _isGenerating = true);

  try { // Mulai blok try
    final model = GenerativeModel(
      model: 'gemini-3-flash-preview:generateContent',
      apiKey: 'AIzaSyBO5pmORprDOdle6gkqPAQWwwSt19P7ia0',
    );
    
    final imageBytes = await _image!.readAsBytes();
    final content = [
      Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori Utama kerusakan fasilitas umum...'
          // (sisa prompt teks kamu)
        ),
      ])
    ];

    final response = await model.generateContent(content);
    final aiText = response.text;
    print("AI Text: $aiText");

    if (aiText != null && aiText.isNotEmpty) {
      final allLines = aiText.trim().split('\n'); // Ubah nama variabel agar tidak bentrok
      String? category;
      String? description;

      for (var line in allLines) { // Iterasi setiap baris
        final lower = line.toLowerCase();
        if (lower.startsWith('kategori:')) {
          category = line.substring(9).trim();
        } else if (lower.startsWith('deskripsi:')) {
          description = line.substring(10).trim();
        } else if (lower.startsWith('keterangan:')) {
          description = line.substring(11).trim();
        }
      }

      description ??= aiText.trim();
      setState(() {
        _aiCategory = category ?? 'Tidak Diketahui';
        _aiDescription = description;
        _descriptionController.text = _aiDescription!;
      });
    }
  } catch (e) { // Sekarang catch sudah punya pasangan try yang benar
    debugPrint('Failed to generate AI description: $e');
  } finally {
    if (mounted) setState(() => _isGenerating = false);
  }
}

Future<void> _getLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.'))
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.'))
        );
        return;
      }
    }
    final position  = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(const Duration(seconds: 10));
    setState(() {
      _Latitude = position.latitude;
      _Longitude = position.longitude;
    });
  } catch (e) {
    debugPrint('Failed to retrieve location: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to retrieve location: $e')),
    );
    setState(() {
      _Latitude = null;
      _Longitude = null;
    });
  }
}

void _showImageSourceDialog() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _submitPost() async {
  if (_base64Image == null || _descriptionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add an image and description.')),
    );
    return;
  }
  setState(() => _isUploading = true);
  final now = DateTime.now().toIso8601String();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not found. Please sign in.')),
    );
    return;
  }
  try {
    await _getLocation();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final fullName = userDoc.data()?['fullName'] ?? 'Anonymous';
    await FirebaseFirestore.instance.collection('posts').add({
      'image': _base64Image,
      'description': _descriptionController.text,
      'category': _aiCategory ?? 'Tidak Diketahui',
      'createdAt': now,
      'Latitude': _Latitude,
      'Longitude': _Longitude,
      'fullName': fullName,
      'userId': uid,
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post updated successfully!')),
    );
  } catch (e) {
    debugPrint('Upload failed: $e');
    if (!mounted) return;
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload post: $e')));
  } finally {
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover, 
                        ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                ),
              ),
              const SizedBox(height: 16),
              // efek shimmer saat generating
              if (_isGenerating)
                Shimmer.fromColors(
                  baseColor: Colors.deepPurple[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                      ),
                      Container(
                        height:  80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                       
                      )
                    ],
                  ),
                ),
              // kategori dan tombol refresh
              if (_aiCategory != null && !_isGenerating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                     GestureDetector(
                      onTap: _showCategorySelectionDialog,
                      child: Chip(
                        label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_aiCategory!),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit, size: 16),
                        ],
                      ),
                      backgroundColor: Colors.blue[100],
                      ),
                     ),
                     if (_image != null)
                     IconButton(
                       icon : const Icon (Icons.refresh),
                       tooltip: 'Regenerate AI description',
                       onPressed: _generateDescriptionWithAI,
                     ),
                    ],
                  ),
                ),
              // TextField untuk deskripsi
                Offstage(
                  offstage: _isGenerating,
                  child: TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Enter description...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // tombol kirim post
                ElevatedButton(
                  onPressed: _isUploading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(),
                  child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Post'),
                ),
            ],
          ),
        ),
    );
