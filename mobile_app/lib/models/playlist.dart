import 'track.dart';

class Playlist {
  final String id;
  String name;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    required this.tracks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var tracksList = json['tracks'] as List? ?? [];
    List<Track> tracks = tracksList.map((t) => Track.fromJson(t)).toList();
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Playlist',
      tracks: tracks,
    );
  }
}
