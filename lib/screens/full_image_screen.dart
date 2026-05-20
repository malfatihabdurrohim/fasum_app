import 'package:flutter/material.dart';
import 'dart:convert';

class FullImageScreen extends StatefulWidget {
  const FullImageScreen({
    super.key,
    required this.imageBase64
    });
  final String imageBase64;
  @override
  State<FullImageScreen> createState() => FullImageScreenState();
}

class FullImageScreenState extends State<FullImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: InteractiveViewer(
            child: Image.memory(
              base64Decode(widget.imageBase64),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}