import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _likedSongsKey = 'liked_songs';
  static const String _playedSongsKey = 'played_songs';
  static const String _playlistsKey = 'playlists';

  // Load Liked Songs
  Future<List<Track>> loadLikedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_likedSongsKey);
      if (jsonStr == null) return [];
      
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => Track.fromJson(item)).toList();
    } catch (err) {
      print('Load Liked Songs failed: $err');
      return [];
    }
  }

  // Save Liked Songs
  Future<void> saveLikedSongs(List<Track> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(tracks.map((t) => t.toJson()).toList());
      await prefs.setString(_likedSongsKey, jsonStr);
    } catch (err) {
      print('Save Liked Songs failed: $err');
    }
  }

  // Load Recently Played
  Future<List<Track>> loadPlayedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_playedSongsKey);
      if (jsonStr == null) return [];
      
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => Track.fromJson(item)).toList();
    } catch (err) {
      print('Load Played Songs failed: $err');
      return [];
    }
  }

  // Save Recently Played
  Future<void> savePlayedSongs(List<Track> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(tracks.map((t) => t.toJson()).toList());
      await prefs.setString(_playedSongsKey, jsonStr);
    } catch (err) {
      print('Save Played Songs failed: $err');
    }
  }

  // Load Playlists
  Future<List<Playlist>> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_playlistsKey);
      if (jsonStr == null) return [];
      
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => Playlist.fromJson(item)).toList();
    } catch (err) {
      print('Load Playlists failed: $err');
      return [];
    }
  }

  // Save Playlists
  Future<void> savePlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_playlistsKey, jsonStr);
    } catch (err) {
      print('Save Playlists failed: $err');
    }
  }
}
