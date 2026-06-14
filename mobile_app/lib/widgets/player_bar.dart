import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playback_provider.dart';
import '../models/track.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);
    final track = provider.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 64 + 8, // float just above bottom navigation (64 height) + padding
      left: 8,
      right: 8,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: const Color(0xFF121212),
            builder: (context) => const FullPlayerScreen(),
          );
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Track cover
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: track.thumbnail,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white55),
                ),
              ),
              const SizedBox(width: 10),
              
              // Track Title + Artists
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

              // Like Toggle
              IconButton(
                icon: Icon(
                  provider.isTrackLiked(track.videoId) ? Icons.favorite : Icons.favorite_border,
                  color: provider.isTrackLiked(track.videoId) ? const Color(0xFF1DB954) : Colors.white70,
                  size: 20,
                ),
                onPressed: () => provider.toggleLike(track),
              ),

              // Play/Pause button
              provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => provider.togglePlayPause(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// FULL SCREEN PLAYER MODAL SHEET
// ----------------------------------------------------

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaybackProvider>(context);
    final track = provider.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            const Spacer(),
            
            // Large Album Artwork
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                elevation: 12,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: track.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 100),
                ),
              ),
            ),
            
            const Spacer(),

            // Title + Artist + Like button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artists,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    provider.isTrackLiked(track.videoId) ? Icons.favorite : Icons.favorite_border,
                    color: provider.isTrackLiked(track.videoId) ? const Color(0xFF1DB954) : Colors.white,
                    size: 26,
                  ),
                  onPressed: () => provider.toggleLike(track),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Progress Slider
            StreamBuilder<Duration>(
              stream: provider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: provider.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration(seconds: track.durationSeconds);
                    
                    // Constrain position to duration to prevent slider crashing
                    double sliderVal = position.inMilliseconds.toDouble();
                    double maxVal = duration.inMilliseconds.toDouble();
                    if (sliderVal > maxVal) sliderVal = maxVal;
                    if (maxVal <= 0) maxVal = 1.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.12),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: sliderVal,
                            max: maxVal,
                            onChanged: (val) {
                              provider.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Player Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle Button
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: provider.isShuffle ? const Color(0xFF1DB954) : Colors.white54,
                    size: 24,
                  ),
                  onPressed: () => provider.toggleShuffle(),
                ),

                // Previous Button
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 38),
                  onPressed: () => provider.previous(),
                ),

                // Play / Pause Circle Button
                provider.isLoading
                    ? const SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 36,
                          ),
                          iconSize: 64,
                          padding: EdgeInsets.zero,
                          onPressed: () => provider.togglePlayPause(),
                        ),
                      ),

                // Next Button
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
                  onPressed: () => provider.next(),
                ),

                // Repeat Button
                IconButton(
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.repeat,
                        color: provider.repeatState != 'none' ? const Color(0xFF1DB954) : Colors.white54,
                        size: 24,
                      ),
                      if (provider.repeatState == 'one')
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DB954),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => provider.toggleRepeat(),
                ),
              ],
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
