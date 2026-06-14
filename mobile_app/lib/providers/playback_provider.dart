import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicService _musicService = MusicService();
  final StorageService _storageService = StorageService();

  // State Variables
  Track? _currentTrack;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffle = false;
  String _repeatState = 'none'; // 'none', 'all', 'one'
  
  List<Track> _likedSongs = [];
  List<Track> _playedSongs = [];
  List<Playlist> _playlists = [];
  
  List<Track> _activeQueue = [];
  int _activeQueueIndex = -1;

  // Streams from audio player
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Getters
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffle => _isShuffle;
  String get repeatState => _repeatState;
  
  List<Track> get likedSongs => _likedSongs;
  List<Track> get playedSongs => _playedSongs;
  List<Playlist> get playlists => _playlists;
  
  List<Track> get activeQueue => _activeQueue;
  int get activeQueueIndex => _activeQueueIndex;

  PlaybackProvider() {
    _init();
  }

  // Load persisted states
  Future<void> _init() async {
    _likedSongs = await _storageService.loadLikedSongs();
    _playedSongs = await _storageService.loadPlayedSongs();
    _playlists = await _storageService.loadPlaylists();
    notifyListeners();

    // Listen to player state changes (like track ending)
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        _handleTrackEnded();
      }
      notifyListeners();
    });
  }

  // Handle Track Playback
  Future<void> playTrack(Track track, {List<Track>? queue, int? index}) async {
    try {
      _isLoading = true;
      _currentTrack = track;
      notifyListeners();

      // Configure playback queue
      if (queue != null) {
        _activeQueue = queue;
        _activeQueueIndex = index ?? queue.indexOf(track);
      } else {
        // If no queue passed, make single track the queue
        _activeQueue = [track];
        _activeQueueIndex = 0;
      }

      // Add to Liked Songs automatically when played (as requested)
      autoLikeTrack(track);

      // Add to recently played
      _addToRecentlyPlayed(track);

      // Extract stream URL from YouTube
      final url = await _musicService.getAudioStreamUrl(track.videoId);
      if (url == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load streaming source into player
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
      _audioPlayer.play();
      _isLoading = false;
      notifyListeners();
    } catch (err) {
      print('Playback error: $err');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void seek(Duration pos) {
    _audioPlayer.seek(pos);
  }

  // Queue Traversal
  void next() {
    if (_activeQueue.isEmpty || _activeQueueIndex == -1) return;

    int nextIndex = _activeQueueIndex;
    if (_isShuffle) {
      // Pick random
      nextIndex = (DateTime.now().millisecond) % _activeQueue.length;
    } else {
      nextIndex = _activeQueueIndex + 1;
    }

    if (nextIndex >= _activeQueue.length) {
      if (_repeatState == 'all') {
        nextIndex = 0;
      } else {
        return; // stop playback
      }
    }

    playTrack(_activeQueue[nextIndex], queue: _activeQueue, index: nextIndex);
  }

  void previous() {
    if (_activeQueue.isEmpty || _activeQueueIndex == -1) return;

    int prevIndex = _activeQueueIndex - 1;
    if (prevIndex < 0) {
      prevIndex = 0; // go to start of track
      _audioPlayer.seek(Duration.zero);
      return;
    }

    playTrack(_activeQueue[prevIndex], queue: _activeQueue, index: prevIndex);
  }

  void _handleTrackEnded() {
    if (_repeatState == 'one') {
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } else {
      next();
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    if (_repeatState == 'none') {
      _repeatState = 'all';
    } else if (_repeatState == 'all') {
      _repeatState = 'one';
    } else {
      _repeatState = 'none';
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // LIBRARY & PLAYLIST MANAGEMENT
  // ----------------------------------------------------

  bool isTrackLiked(String videoId) {
    return _likedSongs.any((t) => t.videoId == videoId);
  }

  void autoLikeTrack(Track track) {
    if (!isTrackLiked(track.videoId)) {
      _likedSongs.insert(0, track);
      _storageService.saveLikedSongs(_likedSongs);
      notifyListeners();
    }
  }

  void toggleLike(Track track) {
    if (isTrackLiked(track.videoId)) {
      _likedSongs.removeWhere((t) => t.videoId == track.videoId);
    } else {
      _likedSongs.insert(0, track);
    }
    _storageService.saveLikedSongs(_likedSongs);
    notifyListeners();
  }

  void _addToRecentlyPlayed(Track track) {
    _playedSongs.removeWhere((t) => t.videoId == track.videoId);
    _playedSongs.insert(0, track);
    if (_playedSongs.length > 50) {
      _playedSongs = _playedSongs.sublist(0, 50);
    }
    _storageService.savePlayedSongs(_playedSongs);
    notifyListeners();
  }

  // Playlists CRUD
  void createPlaylist(String name) {
    final newPlaylist = Playlist(
      id: 'playlist-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tracks: [],
    );
    _playlists.add(newPlaylist);
    _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  void renamePlaylist(String id, String newName) {
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _playlists[idx].name = newName;
      _storageService.savePlaylists(_playlists);
      notifyListeners();
    }
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _storageService.savePlaylists(_playlists);
    notifyListeners();
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final playlist = _playlists[idx];
      if (!playlist.tracks.any((t) => t.videoId == track.videoId)) {
        playlist.tracks.add(track);
        _storageService.savePlaylists(_playlists);
        notifyListeners();
      }
    }
  }

  void removeTrackFromPlaylist(String playlistId, String videoId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      _playlists[idx].tracks.removeWhere((t) => t.videoId == videoId);
      _storageService.savePlaylists(_playlists);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _musicService.dispose();
    super.dispose();
  }
}
