// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'audio_manager.dart';

class RecommendationScreen extends StatefulWidget {
  final String userId;
  final List<String> favoriteGenres;

  const RecommendationScreen({
    super.key,
    required this.userId,
    required this.favoriteGenres,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final String backendUrl = "http://10.0.2.2:5000";

  bool isLoading = true;
  List<Map<String, dynamic>> tracks = [];
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
    _fetchRecommendations();
  }

  // ---------------- FETCH FAVORITES ----------------
  Future<void> _fetchFavorites() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      setState(() {
        favorites =
            List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  // ---------------- FETCH RECOMMENDATIONS ----------------
  Future<void> _fetchRecommendations() async {
    try {
      final response = await http.post(
        Uri.parse("$backendUrl/recommendations"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "favoriteGenres": widget.favoriteGenres,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tracks = List<Map<String, dynamic>>.from(data["results"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
      setState(() => isLoading = false);
    }
  }

  // ---------------- PLAY / PAUSE + SAVE HISTORY ----------------
  Future<void> _playOrPause(Map<String, dynamic> track) async {
    final url = track["audio"];
    if (url == null) return;

    final previousUrl = AudioManager.currentlyPlayingUrlNotifier.value;

    await AudioManager.playOrPause(url, track);

    // Save to Firestore history ONLY when a NEW track starts
    if (previousUrl != url) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      final snapshot = await userDoc.get();
      List<dynamic> history = snapshot.data()?['history'] ?? [];

      history.removeWhere((t) => t['audio'] == track['audio']);
      history.insert(0, track);

      await userDoc.set({'history': history}, SetOptions(merge: true));
    }
  }

  // ---------------- TOGGLE FAVORITE ----------------
  Future<void> _toggleFavorite(Map<String, dynamic> track) async {
    final isFav = favorites.any((t) => t["audio"] == track["audio"]);
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    List<dynamic> updated = List.from(favorites);

    if (isFav) {
      updated.removeWhere((t) => t["audio"] == track["audio"]);
    } else {
      updated.add(track);
    }

    await userDoc.set({'favorites': updated}, SetOptions(merge: true));

    setState(() {
      favorites = List<Map<String, dynamic>>.from(updated);
    });
  }

  // ---------------- TRACK CARD ----------------
  Widget _trackCard(Map<String, dynamic> track) {
    const primaryGreen = Color(0xFF1DB954);
    final isFav = favorites.any((t) => t["audio"] == track["audio"]);

    return ValueListenableBuilder<String?>(
      valueListenable: AudioManager.currentlyPlayingUrlNotifier,
      builder: (_, currentUrl, __) {
        final isPlaying = AudioManager.isPlaying(track["audio"]);

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
                    child:
                        const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(color: Colors.white70),
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
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => _toggleFavorite(track),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121212);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text("Recommendations"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tracks.isEmpty
              ? const Center(
                  child: Text(
                    "No recommendations available.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tracks.length,
                  itemBuilder: (_, index) => _trackCard(tracks[index]),
                ),
    );
  }
}
