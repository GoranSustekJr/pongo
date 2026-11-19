import 'package:flutter/widgets.dart';

import '../../../domain/models/playlists/playlist_handler.dart';
import '../../shell/view_models/shell_view_model.dart';

/// Opens the playlist editor over the app.
class OpenPlaylist {
  /// Shows [playlistHandler] in the playlist editor.
  void show(BuildContext context, PlaylistHandler playlistHandler) {
    context.shell.playlistHandler.value = playlistHandler;
  }
}
