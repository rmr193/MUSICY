import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playback_provider.dart';
import '../widgets/playlist_modal.dart';
import 'playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);

    // Combine Liked Songs card and Custom Playlists into a unified view
    final customPlaylists = provider.playlists;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Your Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Playlist',
            onPressed: () {
              PlaylistModal.showCreateOrRenameDialog(
                context: context,
                onSubmit: (name) => provider.createPlaylist(name),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          // 1. Liked Songs List Item
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF450AF5), Color(0xFF8E8EE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 28),
            ),
            title: const Text(
              'Liked Songs',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              'Playlist • ${provider.likedSongs.length} song${provider.likedSongs.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaylistScreen(playlistId: 'liked-songs'),
                ),
              );
            },
          ),

          // Divider between Liked Songs and custom playlists
          if (customPlaylists.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white12, height: 1),
            ),

          // 2. Custom Playlists List Items
          if (customPlaylists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.library_music_outlined, size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text(
                      'No playlists yet.\nTap the + button to create a custom playlist.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = customPlaylists[index];
                final count = playlist.tracks.length;

                Widget artwork;
                if (playlist.tracks.isNotEmpty && playlist.tracks[0].thumbnail.isNotEmpty) {
                  artwork = ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: playlist.tracks[0].thumbnail,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                    ),
                  );
                } else {
                  artwork = Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white55, size: 24),
                  );
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: artwork,
                  title: Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Playlist • $count song${count == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF282828),
                    onSelected: (val) {
                      if (val == 'rename') {
                        PlaylistModal.showCreateOrRenameDialog(
                          context: context,
                          initialValue: playlist.name,
                          onSubmit: (newName) => provider.renamePlaylist(playlist.id, newName),
                        );
                      } else if (val == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF282828),
                            title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                            content: Text('Are you sure you want to delete "${playlist.name}"?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deletePlaylist(playlist.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename', style: TextStyle(color: Colors.white)),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistScreen(playlistId: playlist.id),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
