import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/track.dart';

class MusicService {
  final YoutubeExplode _yt = YoutubeExplode();

  // Search songs on YouTube
  Future<List<Track>> searchSongs(String query, {int limit = 15}) async {
    try {
      if (query.trim().isEmpty) return [];

      // We append 'song' or 'audio' to search terms for better music matching
      final searchQuery = query.toLowerCase().contains('song') || 
                              query.toLowerCase().contains('music') 
                          ? query 
                          : '$query song';
      
      final searchList = await _yt.search.search(searchQuery);
      final List<Track> tracks = [];

      for (final video in searchList.take(limit)) {
        // Skip live streams or videos without duration
        if (video.duration == null || video.duration!.inSeconds == 0) continue;

        final durationSeconds = video.duration!.inSeconds;
        final minutes = video.duration!.inMinutes;
        final seconds = durationSeconds % 60;
        final durationStr = '$minutes:${seconds < 10 ? '0' : ''}$seconds';

        // Extract clean title and artist if title is formatted like "Artist - Title"
        String title = video.title;
        String artist = video.author;
        
        final dashIndex = video.title.indexOf(' - ');
        if (dashIndex != -1) {
          artist = video.title.substring(0, dashIndex).trim();
          title = video.title.substring(dashIndex + 3).trim();
        }

        // Clean up title (remove video bracket fluff like [Official Audio])
        title = title
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .replaceAll(RegExp(r'\(.*?\)'), '')
            .replaceAll(RegExp(r'Official Audio|Official Video|Audio|Video|Lyrics', caseSensitive: false), '')
            .trim();

        tracks.add(Track(
          videoId: video.id.value,
          title: title.isEmpty ? video.title : title,
          artists: artist.isEmpty ? video.author : artist,
          thumbnail: video.thumbnails.mediumResUrl,
          duration: durationStr,
          durationSeconds: durationSeconds,
          album: 'YouTube Music',
        ));
      }

      return tracks;
    } catch (err) {
      print('YouTube search failed: $err');
      return [];
    }
  }

  // Get streamable audio URL for a track
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (err) {
      print('YouTube stream extraction failed for $videoId: $err');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
