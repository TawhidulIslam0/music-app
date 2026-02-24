// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'audio_manager.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // ---------------- FETCH HISTORY ----------------
  Future<void> fetchHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      setState(() {
        history =
            List<Map<String, dynamic>>.from(snapshot.data()?['history'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching history: $e")),
      );
    }
  }

  // ---------------- PLAY / PAUSE ----------------
  Future<void> _playOrPause(Map<String, dynamic> track) async {
    final url = track['audio'];
    if (url == null) return;

    final previousUrl = AudioManager.currentlyPlayingUrlNotifier.value;

    await AudioManager.playOrPause(url, track);

    // Save history ONLY when a new track starts
    if (previousUrl != url) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      final snapshot = await userDoc.get();
      List<dynamic> currentHistory = snapshot.data()?['history'] ?? [];

      currentHistory.removeWhere((t) => t['audio'] == track['audio']);
      currentHistory.insert(0, track);

      // Keep last 50
      if (currentHistory.length > 50) {
        currentHistory = currentHistory.sublist(0, 50);
      }

      await userDoc.set(
        {'history': currentHistory},
        SetOptions(merge: true),
      );

      setState(() {
        history = List<Map<String, dynamic>>.from(currentHistory);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121212);
    const primaryGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text("History", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : history.isEmpty
              ? const Center(
                  child: Text(
                    "No songs played yet",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (_, index) {
                    final track = history[index];

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
                                        fontSize: 14,
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
