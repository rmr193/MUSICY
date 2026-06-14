import 'package:flutter/material.dart';

class PlaylistModal {
  static void showCreateOrRenameDialog({
    required BuildContext context,
    String? initialValue,
    required Function(String) onSubmit,
  }) {
    final controller = TextEditingController(text: initialValue);
    final isRename = initialValue != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            isRename ? 'Rename Playlist' : 'Create Playlist',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFF1DB954),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1DB954)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  onSubmit(name);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(500),
                ),
              ),
              child: Text(
                isRename ? 'RENAME' : 'CREATE',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dropdown dialog to select which playlist to add a track to
  static void showAddToPlaylistSheet({
    required BuildContext context,
    required List playlists,
    required Function(String) onPlaylistSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 16),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                child: Text('Add to playlist'),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: Center(
                    child: Text(
                      'No custom playlists. Create one first.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.white55),
                        title: Text(
                          pl.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                        onTap: () {
                          onPlaylistSelected(pl.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${pl.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
