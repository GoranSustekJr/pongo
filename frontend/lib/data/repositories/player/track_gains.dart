import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/database/track_gains_table.dart';

/// Loudness gains of tracks, in decibels, so tracks play about equally loud.
///
/// Gains are kept in memory and in the database, so downloaded tracks keep
/// theirs offline, and fetched from the server for the rest.
class TrackGains {
  /// Creates gains that are fetched with [_apiClient] and stored in [_table].
  TrackGains({
    required this._apiClient,
    required this._table,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiClient _apiClient;
  final TrackGainsTable _table;
  final DateTime Function() _now;

  static const _batchSize = 500;
  // Tracks the server doesn't have yet aren't asked about again before this
  static const _retryAfter = Duration(minutes: 1);

  final _gains = <String, double>{};
  final _unknownUntil = <String, DateTime>{};

  /// The gain of the track with [stid], or `null` if it isn't known.
  Future<double?> gainFor(String stid) async {
    if (!_gains.containsKey(stid)) await prefetch([stid]);
    return _gains[stid];
  }

  /// Looks up the gains of [stids] that aren't known yet.
  Future<void> prefetch(Iterable<String> stids) async {
    final now = _now();
    final missing = {
      for (final stid in stids)
        if (!_gains.containsKey(stid) &&
            !(_unknownUntil[stid]?.isAfter(now) ?? false))
          stid,
    }.toList();
    if (missing.isEmpty) return;

    _gains.addAll(await _table.query(missing));
    final remote = missing.where((s) => !_gains.containsKey(s)).toList();
    for (var i = 0; i < remote.length; i += _batchSize) {
      final batch = remote.sublist(i, (i + _batchSize).clamp(0, remote.length));
      final result = await _apiClient.post('track_gains', {'stids': batch});
      if (result case Ok(:final value)) {
        final gains = {
          for (final MapEntry(:key, :value)
              in ((value['gains'] as Map?) ?? const {}).entries)
            if (value is num) '$key': value.toDouble(),
        };
        _gains.addAll(gains);
        await _table.upsert(gains);
      }
      for (final stid in batch) {
        if (!_gains.containsKey(stid)) {
          _unknownUntil[stid] = now.add(_retryAfter);
        }
      }
    }
  }
}
