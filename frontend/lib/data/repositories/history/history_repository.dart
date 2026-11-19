/// Source of truth for what the user searched and played.
abstract class HistoryRepository {
  /// Past search queries, latest first.
  Future<List<String>> searches();

  /// Records [query] as the latest search.
  Future<void> addSearch(String query);

  /// Forgets [query].
  Future<void> removeSearch(String query);

  /// Forgets every search.
  Future<void> clearSearches();

  /// IDs of recently played tracks, latest first.
  Future<List<String>> playedTracks({int? limit});

  /// Records the track with [stid] as played.
  Future<void> addPlayedTrack(String stid);

  /// IDs of recently viewed artists, latest first.
  Future<List<String>> viewedArtists({int? limit});

  /// Records the artist with [said] as viewed.
  Future<void> addViewedArtist(String said);
}
