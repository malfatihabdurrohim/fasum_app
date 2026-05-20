import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fasum_app/screens/sign_in_screen.dart';
import 'package:fasum_app/screens/detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCategory;
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

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} Secs Ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} Mins Ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} Hours Ago';
    } else if (diff.inHours < 48) {
      return '1 Days Ago';
    } else {
      return DateFormat('dd/MMM/yyyy').format(dateTime);
    } 
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
    );
  }

  void _showCategoryFilter() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon (Icons.clear),
                  title: const Text('Semua Kategori'),
                  onTap:
                    () => Navigator.pop(
                      context,
                      null,
                    ), // Null untuk memilih semua kategori
                ),
                const Divider(),
                ...categories.map(
                  (category) => ListTile(
                    title: Text (category),
                    trailing:
                    selectedCategory == category
                      ? Icon (
                        Icons.check,
                        color:
                          Theme.of (context).colorScheme.primary,
                        )
                        : null,
                        onTap: () => Navigator.pop(context, category),
                  ),
                ),
              ],
            )
          )
        );
      }
    );
    if (result != null) {
      setState(() { 
        selectedCategory = 
          result;
      });
    } else {
      setState(() {
        selectedCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Fasum",
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Kategori',
          ),
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          stream: FirebaseDatabase.instance.ref('posts').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final data = snapshot.data!.snapshot.value as Map?;
            if (data == null || data.isEmpty) {
              return const Center(
                child: Text("Tidak ada laporan untuk kategori ini."),
              );
            }

            List<MapEntry> postList = data.entries.toList();
            
            // Sort by createdAt descending
            postList.sort((a, b) {
              final aTime = DateTime.parse((a.value['createdAt'] ?? '').toString());
              final bTime = DateTime.parse((b.value['createdAt'] ?? '').toString());
              return bTime.compareTo(aTime);
            });

            final filteredPosts = postList.where((entry) {
              final postData = entry.value;
              final category = postData['category'] ?? 'Lainnya';
              return selectedCategory == null || selectedCategory == category;
            }).toList();

            if (filteredPosts.isEmpty) {
              return const Center(
                child: Text("Tidak ada laporan untuk kategori ini."),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final postData = filteredPosts[index].value;
                final imageBase64 = postData['image'];
                final description = postData['description'];
                final createdAtStr = postData['createdAt'];
                final fullName = postData['fullName'] ?? 'Anonim';
                final latitude = postData['latitude'];
                final longitude = postData['longitude'];
                final category = postData['category'] ?? 'Lainnya';
                final createdAt = DateTime.parse(createdAtStr.toString());
                String heroTag =
                  'fasum-image-${createdAt.millisecondsSinceEpoch}';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          imageBase64: imageBase64,
                          description: description,
                          createdAt: createdAt,
                          fullName: fullName,
                          latitude: latitude,
                          longitude: longitude,
                          category: category,
                          heroTag: heroTag,
                        ),
                      )
                    );  
                  },
                  child: Card(
                    elevation: 1,
                    color:
                    Theme.of(context).colorScheme.surfaceContainerLow,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(imageBase64 != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)
                            ),
                            child: Hero(
                              tag: heroTag,
                              child: Image.memory(
                                base64Decode(imageBase64),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                formatTime(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey       
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description ?? '',
                                style: const TextStyle(fontSize: 16),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ),
                        ),
                      ]
                    )
                  ),
                );
              }
            );
          }
        ),
      ),
    );
  }
}