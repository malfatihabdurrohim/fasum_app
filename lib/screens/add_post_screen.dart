import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {

  File? _image;
  String? base64Image;
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGeneratingAI = false;
  final List<String> _aiCategories = 
  ['Jalan Rusak',
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
  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: _aiCategories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _aiCategory = category;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
  Future<void> _compresssAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compresssedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compresssedImage == null) return;
      setState(() {
        base64Image = _base64Encode(compresssedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to compress image')),
        );
      }
    }
  }
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _captionController.clear();
        });
        await _compresssAndEncodeImage();
        await _generateDescriptionWithAI();
      }
  }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }
  
  String _base64Encode(List<int> bytes) {
    return base64Encode(bytes);
  }
  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGeneratingAI = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: 'AIzaSyBr8NC5HGVFbK8WBZeztM4zgkTlO4wj9WA',
      );
      final imageBytes = await _image!.readAsBytes();
      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori utama kerusakan fasilitas umum dari daftar berikut: Jalan Rusak, Marka Pudar, Lampu Mati, Trotoar Rusak, Rambu Rusak, Jembatan Rusak, Sampah Menumpuk, Saluran Tersumbat, Sungai Tercemar, Sampah Sungai, Pohon Tumbang, Taman Rusak, Fasilitas Rusak, Pipa Bocor, Vandalisme, Banjir, dan Lainnya.\n'
          'Pilih kategori yang paling dominan atau paling mendesak untuk ditanggani.\n'
          'Buat deskripsi singkat untuk laporan perbaikan dan tambahkan pernyataan dan tindakan.\n'
          'Fokus pada kerusakan yang terlihat dan hindari spekulasi.\n\n'
          'Format output yang diinginkan:\n'
          'Kategori: [satu kategori yang disalin]\n'
          'Deskripsi: [deskripsi singkat]',
        ),
      ]);
      final response = await model.generateContent([content]);
      if (response.text != null) {
        setState(() {
          _aiDescription = response.text;
          _isGeneratingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate AI description: $e')),
        );
      }
      setState(() => _isGeneratingAI = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.black38,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih Foto'),
            ),
            const SizedBox(height: 16),
            if (_isGeneratingAI) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            if (_aiCategory != null)
              Text('Kategori AI: $_aiCategory', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_aiDescription != null) ...[
              const SizedBox(height: 8),
              Text(_aiDescription!),
            ],
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 16),
              Text('Lokasi: $_latitude, $_longitude'),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _image == null || _isLoading ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data post disimpan (dummy action)')),
                );
              },
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showCategorySelection,
              child: const Text('Pilih Kategori secara manual'),
            ),
          ],
        ),
      ),
    );
  }
}
