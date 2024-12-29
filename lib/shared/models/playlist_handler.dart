class PlaylistHandler {
  final PlaylistHandlerType type;
  final PlaylistHandlerFunction function;
  final List<PlaylistHandlerTrack>? track;
  List<String> toDownload;

  PlaylistHandler({
    required this.type,
    required this.function,
    required this.track,
    this.toDownload = const [],
  });
}

enum PlaylistHandlerType { online, offline }

enum PlaylistHandlerFunction { addToPlaylist, createPlaylist }

enum PlaylistHandlerCoverType { url, bytes }

abstract class PlaylistHandlerTrack {
  final String id;
  final String name;
  final List<Map<String, dynamic>> artist;
  final String cover;
  final PlaylistHandlerCoverType playlistHandlerCoverType;

  PlaylistHandlerTrack({
    required this.name,
    required this.artist,
    required this.id,
    required this.cover,
    required this.playlistHandlerCoverType,
  });
}

class PlaylistHandlerOnlineTrack extends PlaylistHandlerTrack {
  PlaylistHandlerOnlineTrack({
    required super.id,
    required super.name,
    required super.artist,
    required super.cover,
    required super.playlistHandlerCoverType,
  });
}

class PlaylistHandlerOfflineTrack extends PlaylistHandlerTrack {
  final String filePath;

  PlaylistHandlerOfflineTrack({
    required super.id,
    required super.name,
    required super.artist,
    required super.cover,
    required super.playlistHandlerCoverType,
    required this.filePath,
  });
}
