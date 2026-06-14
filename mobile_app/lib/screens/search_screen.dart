import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playback_provider.dart';
import '../services/music_service.dart';
import '../models/track.dart';
import '../widgets/playlist_modal.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _musicService = MusicService();
  final _searchController = TextEditingController();
  List<Track> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final text = query.trim();
      if (text.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      final results = await _musicService.searchSongs(text);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFF1DB954),
            decoration: InputDecoration(
              hintText: 'What do you want to listen to?',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
              ),
            )
          : _searchResults.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 12),
                        const Text(
                          'Search for songs, artists, or audio streams.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final track = _searchResults[index];
                    final isPlaying = provider.currentTrack?.videoId == track.videoId;
                    final isLiked = provider.isTrackLiked(track.videoId);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: track.thumbnail,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, error) => const Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          color: isPlaying ? const Color(0xFF1DB954) : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artists,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like Button
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? const Color(0xFF1DB954) : Colors.white54,
                            ),
                            onPressed: () => provider.toggleLike(track),
                          ),
                          // Add to Playlist Button
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white54),
                            onPressed: () {
                              PlaylistModal.showAddToPlaylistSheet(
                                context: context,
                                playlists: provider.playlists,
                                onPlaylistSelected: (plId) {
                                  provider.addTrackToPlaylist(plId, track);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        provider.setActiveQueue(_searchResults, index);
                        provider.playTrack(track);
                      },
                    );
                  },
                ),
    );
  }
}
