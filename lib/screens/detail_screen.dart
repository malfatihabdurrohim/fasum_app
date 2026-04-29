import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String imageBase64;
  final String? description;
  final DateTime createdAt;
  final String fullName;
  final double latitude;
  final double longitude;
  final String category;
  final String heroTag;

  const DetailScreen({
    super.key,
    required this.imageBase64,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: const Center(
        child: Text('Detail laporan akan ditampilkan di sini'),
      ),
    );
  }
}