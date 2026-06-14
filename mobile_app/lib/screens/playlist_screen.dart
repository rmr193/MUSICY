import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playback_provider.dart';
import '../models/track.dart';
import '../widgets/playlist_modal.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);
    final isLikedSongs = playlistId == 'liked-songs';

    String title = '';
    List<Track> tracks = [];

    if (isLikedSongs) {
      title = 'Liked Songs';
      tracks = provider.likedSongs;
    } else {
      final pl = provider.playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw Exception('Playlist not found'),
      );
      title = pl.name;
      tracks = pl.tracks;
    }

    // Dynamic gradient color depending on Title hash
    int hash = 0;
    for (var i = 0; i < title.length; i++) {
      hash = title.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final double hue = (hash % 360).abs().toDouble();
    final headerColor = HSVColor.fromAHSV(1.0, hue, 0.6, 0.35).toColor();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // AppBar Hero with Gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColor, const Color(0xFF121212)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 20),
                child: Column(
                  children: [
                    // Large cover
                    Expanded(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isLikedSongs
                            ? Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF450AF5), Color(0xFF8E8EE8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.favorite, color: Colors.white, size: 60),
                              )
                            : tracks.isNotEmpty && tracks[0].thumbnail.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: tracks[0].thumbnail,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.music_note, color: Colors.white54, size: 60),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Playlist • ${tracks.length} song${tracks.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Playlist Play/Shuffle Action Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Play All Button
                  ElevatedButton(
                    onPressed: tracks.isEmpty
                        ? null
                        : () {
                            provider.setActiveQueue(tracks, 0);
                            provider.playTrack(tracks[0]);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.black,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.play_arrow, size: 28),
                  ),
                  const SizedBox(width: 16),
                  
                  // Shuffle Playlist Button
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: provider.isShuffle ? const Color(0xFF1DB954) : Colors.white54,
                    ),
                    onPressed: () {
                      if (tracks.isNotEmpty) {
                        provider.playShuffled(tracks);
                      }
                    },
                  ),
                  
                  const Spacer(),
                  // Edit options for Custom Playlists
                  if (!isLikedSongs) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () {
                        PlaylistModal.showCreateOrRenameDialog(
                          context: context,
                          initialValue: title,
                          onSubmit: (newName) => provider.renamePlaylist(playlistId, newName),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF282828),
                            title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                            content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deletePlaylist(playlistId);
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Go back from playlist screen
                                },
                                child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Playlist Songs List
          tracks.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'This playlist is empty. Search for songs to add them!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final isPlaying = provider.currentTrack?.videoId == track.videoId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: track.thumbnail,
                            width: 44,
                            height: 44,
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
                            // Show Remove Track from Playlist
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                              onPressed: () => provider.removeTrackFromPlaylist(playlistId, track.videoId),
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.setActiveQueue(tracks, index);
                          provider.playTrack(track);
                        },
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
                
          const SliverToBoxAdapter(
            child: SizedBox(height: 160),
          ),
        ],
      ),
    );
  }
}

