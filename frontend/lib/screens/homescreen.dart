// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Shared audio manager
import 'audio_manager.dart';
import 'now_playing_bar.dart';

// Screens
import 'favoritescreen.dart';
import 'historyscreen.dart';
import 'profilescreen.dart';
import 'recommendationscreen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final List<String> initialGenres;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.initialGenres,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String backendBaseUrl = "http://10.0.2.2:5000";
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> tracks = [];
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;
  int _currentIndex = 0;

  late List<String> userGenres;

  @override
  void initState() {
    super.initState();
    userGenres = widget.initialGenres;
    fetchFavorites();
    fetchHomeTracks();
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
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  // ---------------- FETCH HOME TRACKS ----------------
  Future<void> fetchHomeTracks() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$backendBaseUrl/home_tracks"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        tracks = List<Map<String, dynamic>>.from(data["results"] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching home tracks: $e");
    }
    setState(() => isLoading = false);
  }

  // ---------------- SEARCH ----------------
  Future<void> searchTracks(String query) async {
    if (query.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final response =
          await http.get(Uri.parse("$backendBaseUrl/search_song?q=$query"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        tracks = List<Map<String, dynamic>>.from(data["results"] ?? []);
      }
    } catch (e) {
      debugPrint("Error searching tracks: $e");
    }

    setState(() => isLoading = false);
  }

  // ---------------- PLAY / PAUSE + HISTORY ----------------
  Future<void> playSong(Map<String, dynamic> track) async {
    final url = track['audio'];
    if (url == null) return;

    final wasDifferentSong =
        AudioManager.currentlyPlayingUrlNotifier.value != url;

    await AudioManager.playOrPause(url, track);

    // Save to history only if it's a NEW song
    if (wasDifferentSong) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      final snapshot = await userDoc.get();
      List<dynamic> history = snapshot.data()?['history'] ?? [];

      history.removeWhere((t) => t['audio'] == url);
      history.insert(0, track);

      await userDoc.set(
        {'history': history},
        SetOptions(merge: true),
      );
    }

    setState(() {});
  }

  // ---------------- TOGGLE FAVORITE ----------------
  Future<void> toggleFavorite(Map<String, dynamic> track) async {
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
  Widget trackCard(Map<String, dynamic> track) {
    const primaryGreen = Color(0xFF1DB954);

    final isFav = favorites.any((t) => t["audio"] == track["audio"]);
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
                child: const Icon(Icons.music_note, color: Colors.white),
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
                      color: Colors.white, fontWeight: FontWeight.bold),
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
            onPressed: () => playSong(track),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () => toggleFavorite(track),
          ),
        ],
      ),
    );
  }

  // ---------------- BODY SWITCH ----------------
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _homeBody();
      case 1:
        return FavoritesScreen(userId: widget.userId);
      case 2:
        return RecommendationScreen(
          userId: widget.userId,
          favoriteGenres: userGenres,
        );
      case 3:
        return HistoryScreen(userId: widget.userId);
      default:
        return _homeBody();
    }
  }

  Widget _homeBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onSubmitted: searchTracks,
            decoration: InputDecoration(
              hintText: "Search songs...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tracks.length,
                  itemBuilder: (_, i) => trackCard(tracks[i]),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121212);
    const primaryGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text(
          "Discover",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),

      // 🔥 THIS IS THE IMPORTANT PART
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const NowPlayingBar(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "For You"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}
