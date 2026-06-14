import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playback_provider.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hr = DateTime.now().hour;
    if (hr < 12) return 'Good morning';
    if (hr < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);
    final greeting = _getGreeting();

    // Setup Quick Play List
    final quickItems = <Map<String, dynamic>>[];
    quickItems.add({
      'id': 'liked-songs',
      'name': 'Liked Songs',
      'isLiked': true,
      'tracks': provider.likedSongs,
    });
    for (var pl in provider.playlists.take(5)) {
      quickItems.add({
        'id': pl.id,
        'name': pl.name,
        'isLiked': false,
        'tracks': pl.tracks,
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Header Welcome Greeting
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            expandedHeight: 80,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),

          // Quick Play Grid (2 Columns)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = quickItems[index];
                  final isLiked = item['isLiked'] as bool;
                  final name = item['name'] as String;
                  final tracks = item['tracks'] as List;

                  Widget artwork;
                  if (isLiked) {
                    artwork = Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF450AF5), Color(0xFF8E8EE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                    );
                  } else if (tracks.isNotEmpty && tracks[0].thumbnail.isNotEmpty) {
                    artwork = CachedNetworkImage(
                      imageUrl: tracks[0].thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                    );
                  } else {
                    artwork = Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.music_note, color: Colors.white55),
                    );
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistScreen(playlistId: item['id']),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: artwork,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Mini Play Overlay
                          if (tracks.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Color(0xFF1DB954), size: 32),
                              onPressed: () {
                                provider.setActiveQueue(tracks.cast(), 0);
                                provider.playTrack(tracks[0]);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: quickItems.length,
              ),
            ),
          ),

          // Recently Played Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 12),
              child: Text(
                'Recently played',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // Recently Played Track Cards (Horizontal List)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: provider.playedSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Songs you play will appear here.',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.playedSongs.length,
                      itemBuilder: (context, index) {
                        final track = provider.playedSongs[index];
                        return InkWell(
                          onTap: () {
                            provider.setActiveQueue(provider.playedSongs, index);
                            provider.playTrack(track);
                          },
                          child: Container(
                            width: 128,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: track.thumbnail,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[900]),
                                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  track.artists,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          const SliverSpacer200(),
        ],
      ),
    );
  }
}

class SliverSpacer200 extends StatelessWidget {
  const SliverSpacer200({super.key});
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox(height: 160));
  }
}
