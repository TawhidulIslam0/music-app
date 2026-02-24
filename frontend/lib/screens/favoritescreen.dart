// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'audio_manager.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // ---------------- FETCH FAVORITES ----------------
  Future<void> fetchFavorites() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      setState(() {
        favorites =
            List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching favorites: $e")),
      );
    }
  }

  // ---------------- REMOVE FROM FAVORITES ----------------
  Future<void> removeFromFavorites(Map<String, dynamic> track) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    List<dynamic> currentFavorites = List.from(favorites);
    currentFavorites.removeWhere((t) => t['audio'] == track['audio']);

    await userDoc.set({'favorites': currentFavorites}, SetOptions(merge: true));

    setState(() {
      favorites = List<Map<String, dynamic>>.from(currentFavorites);
    });
  }

  // ---------------- PLAY / PAUSE ----------------
  Future<void> _playOrPause(Map<String, dynamic> track) async {
    final url = track['audio'];
    if (url == null) return;

    await AudioManager.playOrPause(url, track);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121212);
    const primaryGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text("My Favorites"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : favorites.isEmpty
              ? const Center(
                  child: Text(
                    "No favorite songs yet.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (_, index) {
                    final track = favorites[index];

                    return ValueListenableBuilder<String?>(
                      valueListenable:
                          AudioManager.currentlyPlayingUrlNotifier,
                      builder: (_, currentUrl, __) {
                        final isPlaying =
                            AudioManager.isPlaying(track['audio']);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  track["albumArt"] ?? "",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track["title"] ?? "Unknown",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      track["artist"] ?? "Unknown",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: primaryGreen,
                                  size: 32,
                                ),
                                onPressed: () => _playOrPause(track),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeFromFavorites(track),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
