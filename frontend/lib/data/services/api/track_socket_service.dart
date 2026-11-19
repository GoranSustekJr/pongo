import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../config/app_config.dart';

/// The state of a track on the server while it's being made playable.
sealed class TrackAvailability {
  const TrackAvailability();
}

/// The server doesn't have the track yet and started fetching it.
final class TrackDownloading extends TrackAvailability {
  /// Creates a downloading state.
  const TrackDownloading();
}

/// The track can be streamed.
final class TrackReady extends TrackAvailability {
  /// Creates a ready state for a track lasting [durationSeconds].
  const TrackReady(this.durationSeconds);

  /// The length of the track in seconds.
  final double durationSeconds;
}

/// The server couldn't fetch the track.
final class TrackUnavailable extends TrackAvailability {
  /// Creates an unavailable state.
  const TrackUnavailable();
}

/// A track the server added to a mix, with its length.
typedef MixEntry = ({Map<String, dynamic> track, double durationSeconds});

/// WebSocket endpoints that make tracks available on the server.
class TrackSocketService {
  /// Creates a service for the server in [_config].
  TrackSocketService({required this._config});

  final AppConfig _config;

  /// Returns the access token sent when a socket opens.
  String? Function()? accessTokenProvider;

  /// Renews the access token, returning whether it succeeded.
  Future<bool> Function()? refreshSession;

  WebSocketChannel _connect(String path) =>
      WebSocketChannel.connect(Uri.parse('${_config.socketUrl}$path'));

  /// Asks the server to make the track with [stid] playable.
  ///
  /// Emits [TrackDownloading] if the server has to fetch it first, then ends
  /// with [TrackReady] or [TrackUnavailable]. A rejected token is renewed once.
  Stream<TrackAvailability> watchAvailability(String stid) async* {
    var renewed = false;
    while (true) {
      final channel = _connect('test');
      channel.sink.add(
        jsonEncode({'stid': stid, 'at+JWT': accessTokenProvider?.call()}),
      );
      final messages = StreamIterator(channel.stream);
      try {
        if (!await messages.moveNext()) {
          yield const TrackUnavailable();
          return;
        }
        final exists = _decode(messages.current)['exists'];
        if (exists != 'true' && exists != 'false') {
          if (renewed) return;
          renewed = true;
          await refreshSession?.call();
          continue;
        }
        if (exists == 'false') yield const TrackDownloading();

        if (!await messages.moveNext()) {
          yield const TrackUnavailable();
          return;
        }
        final duration = _decode(messages.current)['duration'];
        yield duration is num
            ? TrackReady(duration.toDouble())
            : const TrackUnavailable();
        return;
      } finally {
        await messages.cancel();
        await channel.sink.close();
      }
    }
  }

  /// Opens a session that fetches the tracks with [stids], in that order.
  ///
  /// All of them are sent up front, so the server fetches the next ones while
  /// the app waits for the first.
  TrackBatchSession openBatch(List<String> stids) {
    final channel = _connect('concenating_stids');
    channel.sink.add(
      jsonEncode({
        'stids': stids.length,
        'at+JWT': accessTokenProvider?.call(),
      }),
    );
    for (final stid in stids) {
      channel.sink.add(jsonEncode({'stid': stid}));
    }
    return TrackBatchSession._(channel);
  }

  /// Streams tracks similar to the one with [stid] as the server fetches them.
  Stream<MixEntry> watchMix(String stid) async* {
    final channel = _connect(
      'cfc14e13ca191618a06bd94dd5976fccae585e36b3f651b467947288afb51ea8',
    );
    channel.sink.add(
      jsonEncode({'stid': stid, 'at+JWT': accessTokenProvider?.call()}),
    );
    try {
      await for (final message in channel.stream) {
        final response = _decode(message);
        final duration = response['duration'];
        if (duration is num) {
          yield (
            track: response['track'] as Map<String, dynamic>,
            durationSeconds: duration.toDouble(),
          );
        }
      }
    } finally {
      await channel.sink.close();
    }
  }
}

/// A socket that reports fetched tracks in order, opened by
/// [TrackSocketService.openBatch].
class TrackBatchSession {
  TrackBatchSession._(this._channel)
    : _messages = StreamIterator(_channel.stream);

  final WebSocketChannel _channel;
  final StreamIterator<dynamic> _messages;

  /// Waits for the next track of the batch and returns its length in seconds,
  /// or `null` if the server couldn't get it.
  Future<double?> next() async {
    if (!await _messages.moveNext()) return null;
    final duration = _decode(_messages.current)['duration'];
    return duration is num ? duration.toDouble() : null;
  }

  /// Closes the socket.
  Future<void> close() async {
    await _messages.cancel();
    await _channel.sink.close();
  }
}

Map<String, dynamic> _decode(dynamic message) =>
    jsonDecode(message as String) as Map<String, dynamic>;
