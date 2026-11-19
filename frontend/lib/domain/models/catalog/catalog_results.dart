import 'package:freezed_annotation/freezed_annotation.dart';

import 'album.dart';
import 'artist.dart';
import 'category.dart';
import 'playlist.dart';
import 'track.dart';

part 'catalog_results.freezed.dart';

/// Which tracks of a list the server can stream right away.
@freezed
abstract class TrackAvailabilityMap with _$TrackAvailabilityMap {
  /// Creates availability info.
  const factory TrackAvailabilityMap({
    /// Length in seconds of each track the server already has.
    required Map<String, double> durations,

    /// IDs of the tracks the server has to fetch first.
    required List<String> missing,
  }) = _TrackAvailabilityMap;

  /// Parses the `durations` and `missing_tracks` fields of an API response.
  factory TrackAvailabilityMap.fromMap(Map<String, dynamic> map) =>
      TrackAvailabilityMap(
        durations: {
          for (final item in map['durations'] as List? ?? const [])
            (item as List)[0] as String: (item[1] as num).toDouble(),
        },
        missing: [
          for (final stid in map['missing_tracks'] as List? ?? const [])
            if (stid != null && stid != 'null') stid.toString(),
        ],
      );
}

/// The tracks of an album or playlist and which of them can play right away.
@freezed
abstract class TrackListing with _$TrackListing {
  /// Creates a listing.
  const factory TrackListing({
    required List<Track> tracks,
    required TrackAvailabilityMap availability,
  }) = _TrackListing;
}

/// An artist's releases and top tracks.
@freezed
abstract class ArtistDetails with _$ArtistDetails {
  /// Creates artist details.
  const factory ArtistDetails({
    /// Full length albums.
    required List<Album> albums,

    /// Singles, EPs and compilations.
    required List<Album> otherReleases,
    required List<Track> tracks,
  }) = _ArtistDetails;
}

/// The results of a catalog search.
@freezed
abstract class SearchResults with _$SearchResults {
  /// Creates search results.
  const factory SearchResults({
    @Default(<Track>[]) List<Track> tracks,
    @Default(<Artist>[]) List<Artist> artists,
    @Default(<Album>[]) List<Album> albums,
    @Default(<Playlist>[]) List<Playlist> playlists,
  }) = _SearchResults;
}

/// The content of the home screen.
@freezed
abstract class HomeFeed with _$HomeFeed {
  /// Creates a home feed.
  const factory HomeFeed({
    /// Tracks recommended from the play history.
    @Default(<Track>[]) List<Track> history,
    @Default(<SpCategory>[]) List<SpCategory> categories,
    @Default(<Album>[]) List<Album> newReleases,
    @Default(<Track>[]) List<Track> topTracks,
    @Default(<Artist>[]) List<Artist> topArtists,
    @Default(<Playlist>[]) List<Playlist> topPlaylists,
  }) = _HomeFeed;
}

/// A song recognized by Shazam.
@freezed
abstract class ShazamMatch with _$ShazamMatch {
  /// Creates a match.
  const factory ShazamMatch({
    required String title,
    required String subtitle,

    /// URL of the cover art.
    required String coverArt,
  }) = _ShazamMatch;
}
