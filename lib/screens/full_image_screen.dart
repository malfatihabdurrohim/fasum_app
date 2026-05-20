import 'package:flutter/material.dart';
import 'dart:convert';

class FullImageScreen extends StatefulWidget {
  const FullImageScreen({
    super.key,
    required this.imageBase64,
  });

  final String imageBase64;

  @override
  State<FullImageScreen> createState() => FullImageScreenState();
}

class FullImageScreenState extends State<FullImageScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
