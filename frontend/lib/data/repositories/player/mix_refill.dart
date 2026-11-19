import 'dart:async';
import 'dart:math';

import '../../../utils/result.dart';

/// A track the server added to a mix, with its length.
typedef MixEntry = ({Map<String, dynamic> track, double durationSeconds});

/// Asks the server for [count] tracks similar to [seeds], the most recent
/// first, leaving out [exclude].
typedef FetchMix = Future<Result<List<MixEntry>>> Function({
  required List<String> seeds,
  required List<String> exclude,
  required int count,
});

/// Keeps a mix going by fetching more similar tracks whenever the queue is
/// nearly done.
///
/// Only one request runs at a time, answers for a mix that has since stopped
/// are dropped, and after a failure it tries again with growing delays.
class MixRefill {
  /// Creates a refill that gets tracks from [_fetch] and queues them with
  /// [_append].
  MixRefill({
    required this._fetch,
    required this._append,
    Duration Function(int failures)? retryDelay,
  }) : _retryDelay = retryDelay ?? _defaultRetryDelay;

  /// Tracks left after the current one when more are fetched.
  static const refillWhenLeft = 2;

  /// Tracks fetched per request.
  static const batchSize = 3;

  /// Recently played tracks the next ones are chosen from.
  static const seedCount = 5;

  final FetchMix _fetch;
  final Future<void> Function(List<MixEntry> entries) _append;
  final Duration Function(int failures) _retryDelay;

  // Incremented whenever a mix starts or stops, so older requests are ignored.
  int _session = 0;
  bool _active = false;
  int? _fetchingFor;
  int _failures = 0;
  Timer? _retry;
  List<String> _queue = const [];
  int? _position;

  static Duration _defaultRetryDelay(int failures) =>
      Duration(seconds: min(5 * pow(2, failures - 1).toInt(), 300));

  /// Whether a mix is running.
  bool get isActive => _active;

  /// Starts a new mix, replacing any running one.
  void start() {
    _reset();
    _active = true;
  }

  /// Stops the mix and ignores any request still running.
  void stop() {
    _reset();
    _active = false;
  }

  void _reset() {
    _session++;
    _fetchingFor = null;
    _failures = 0;
    _retry?.cancel();
    _retry = null;
  }

  /// Reports the queue's track IDs in play order and the [position] of the
  /// current one, and fetches more tracks if the queue is nearly done.
  void update(List<String> queue, int? position) {
    _queue = queue;
    _position = position;
    _check();
  }

  void _check() {
    final position = _position;
    if (!_active || position == null || position >= _queue.length) return;
    if (_queue.length - 1 - position > refillWhenLeft) return;
    if (_fetchingFor == _session || _retry != null) return;
    unawaited(_refill(position));
  }

  Future<void> _refill(int position) async {
    final session = _fetchingFor = _session;
    final played = _queue.sublist(0, position + 1).reversed;
    var entries = const <MixEntry>[];
    try {
      final result = await _fetch(
        seeds: played.take(seedCount).toList(),
        exclude: _queue.toSet().toList(),
        count: batchSize,
      );
      if (session != _session) return;
      final queued = _queue.toSet();
      if (result case Ok(:final value)) {
        entries = [
          for (final entry in value)
            if (queued.add('${entry.track['id']}')) entry,
        ];
      }
      if (entries.isNotEmpty) {
        await _append(entries);
        _failures = 0;
        // Counted now, since the player reports the longer queue only later
        _queue = [..._queue, for (final e in entries) '${e.track['id']}'];
      }
    } on Exception {
      entries = const [];
    }
    if (session != _session) return;
    _fetchingFor = null;

    if (entries.isEmpty) {
      // Also when the server had nothing new, so it isn't asked again at once
      _failures++;
      _retry = Timer(_retryDelay(_failures), () {
        _retry = null;
        _check();
      });
    } else {
      // The queue may have moved on while the tracks were fetched
      _check();
    }
  }
}
