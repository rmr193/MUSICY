class Track {
  final String videoId;
  final String title;
  final String artists;
  final String thumbnail;
  final String duration;
  final int durationSeconds;
  final String album;

  Track({
    required this.videoId,
    required this.title,
    required this.artists,
    required this.thumbnail,
    required this.duration,
    required this.durationSeconds,
    this.album = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'artists': artists,
      'thumbnail': thumbnail,
      'duration': duration,
      'durationSeconds': durationSeconds,
      'album': album,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artists: json['artists'] ?? 'Unknown Artist',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
      album: json['album'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId;

  @override
  int get hashCode => videoId.hashCode;
}
