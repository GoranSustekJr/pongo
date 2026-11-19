import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/lyrics/lyrics_repository.dart';
import '../../../data/repositories/player/media_items.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/services/device/connectivity_service.dart';
import '../../../utils/platform.dart';
import '../../core/app_icons.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// The track being played with its lyrics, for the playing details and
/// full screen player.
class NowPlayingViewModel extends ChangeNotifier {
  /// Creates a view model that follows the player.
  ///
  /// `blurhash` is the player's blurhash of the current cover, `null` until
  /// one is known, and `defaultBlurhash` is used then.
  NowPlayingViewModel({
    required this._player,
    required this._lyrics,
    required this._settings,
    required this._connectivity,
    required this._messages,
    required this._blurhash,
    required this._defaultBlurhash,
  }) : _useSyncedLyric = _settings.settings.useSyncedLyrics,
       _currentBlurhash = _blurhash.value ?? _defaultBlurhash {
    _blurhash.addListener(_onBlurhashChanged);
    _item = _player.currentItemStream.listen(_onItemChanged);
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _shiftBlurhash(),
    );
  }

  static const _blurhashCharacters =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      '#%*+,-.:;=?@[]^_{|}~';

  final PlayerRepository _player;
  final LyricsRepository _lyrics;
  final SettingsRepository _settings;
  final ConnectivityService _connectivity;
  final MessageCenter _messages;
  final ValueListenable<String?> _blurhash;
  final String _defaultBlurhash;
  final _random = Random();
  late final StreamSubscription<MediaItem?> _item;
  late final Timer _timer;

  MediaItem? _currentMediaItem;
  String? _currentMediaItemId;
  String _currentBlurhash;
  String _syncedLyrics = '';
  String _plainLyrics = '';
  bool _lyricsOn = kIsDesktop;
  bool _useSyncedLyric;
  bool _showQueue = false;
  int _syncTimeDelay = 0;
  bool _lyricsExist = true;

  /// The entry being played.
  MediaItem? get currentMediaItem => _currentMediaItem;

  /// The ID of the track being played.
  String? get currentMediaItemId => _currentMediaItemId;

  /// The background blurhash, which slowly shifts when dynamic blurhash is
  /// on.
  String get blurhash => _currentBlurhash;

  /// The synced lyrics in LRC format, or empty.
  String get syncedLyrics => _syncedLyrics;

  /// The plain lyrics, or empty.
  String get plainLyrics => _plainLyrics;

  /// Whether the lyrics are shown.
  bool get lyricsOn => _lyricsOn;

  /// Whether synced lyrics are shown instead of plain ones.
  bool get useSyncedLyric => _useSyncedLyric;

  /// Whether the queue is shown.
  bool get showQueue => _showQueue;

  /// The lyrics offset in milliseconds.
  int get syncTimeDelay => _syncTimeDelay;

  /// Whether lyrics were found for the track.
  bool get lyricsExist => _lyricsExist;

  void _onBlurhashChanged() {
    _currentBlurhash = _blurhash.value ?? _defaultBlurhash;
    notifyListeners();
  }

  void _shiftBlurhash() {
    if (_currentBlurhash.isEmpty || !_settings.settings.useDynamicBlurhash) {
      return;
    }
    final chars = _currentBlurhash.split('');
    for (final index in const [2, 4, 15]) {
      if (chars.length > index) {
        chars[index] =
            _blurhashCharacters[_random.nextInt(_blurhashCharacters.length)];
      }
    }
    _currentBlurhash = chars.join();
    notifyListeners();
  }

  Future<void> _onItemChanged(MediaItem? item) async {
    if (item == null || item.stid == _currentMediaItemId) return;
    _currentMediaItemId = item.stid;
    _currentMediaItem = item;
    notifyListeners();

    final connected = !kIsMobile || _connectivity.isConnected;
    if (_settings.settings.enableLyrics && connected) {
      final stid = item.stid;
      final lyrics = await _lyrics.lyrics(
        name: item.title,
        artist: item.artist ?? '',
        album: item.album ?? '',
        duration: item.duration ?? Duration.zero,
      );
      final delay = await _lyrics.syncDelay(stid);
      // A later track may have started while these loaded.
      if (stid != _currentMediaItemId) return;
      _syncTimeDelay = delay;
      _plainLyrics = lyrics.plain;
      _syncedLyrics = lyrics.synced;
      _lyricsExist = _plainLyrics != '' && _syncedLyrics != '';
    } else {
      _plainLyrics = '';
      _syncedLyrics = '';
      _lyricsExist = false;
    }
    notifyListeners();
  }

  /// Shows or hides the lyrics, telling the user when there are none.
  void toggleLyricsOn() {
    _lyricsOn = !_lyricsOn;
    if (!_lyricsExist) {
      _messages.show(
        InfoMessage(
          title: (l10n) => l10n.nolyricsavailable,
          body: (l10n) => l10n.wanttohelpoutlyrics,
          icon: AppIcons.lyrics,
        ),
      );
    }
    notifyListeners();
  }

  /// Switches between synced and plain lyrics.
  void toggleUseSyncedLyrics() {
    _useSyncedLyric = !_useSyncedLyric;
    notifyListeners();
  }

  /// Shows or hides the queue.
  void toggleShowQueue() {
    _showQueue = !_showQueue;
    notifyListeners();
  }

  /// Sets the lyrics offset back to zero.
  void resetSyncTimeDelay() => _setSyncTimeDelay(0);

  /// Shows the lyrics a quarter second later.
  void increaseSyncTimeDelay() => _setSyncTimeDelay(_syncTimeDelay + 250);

  /// Shows the lyrics a quarter second earlier.
  void decreaseSyncTimeDelay() => _setSyncTimeDelay(_syncTimeDelay - 250);

  void _setSyncTimeDelay(int milliseconds) {
    _syncTimeDelay = milliseconds;
    notifyListeners();
  }

  /// Remembers the lyrics offset for the current track.
  Future<void> saveSyncTimeDelay() async {
    final stid = _currentMediaItemId;
    if (stid == null) return;
    await _lyrics.saveSyncDelay(stid, _syncTimeDelay);
    _messages.show(
      InfoMessage(
        title: (l10n) => l10n.successful,
        body: (l10n) => l10n.successfullysavedsynctimedelay,
        icon: CupertinoIcons.time,
      ),
    );
  }

  @override
  void dispose() {
    _blurhash.removeListener(_onBlurhashChanged);
    unawaited(_item.cancel());
    _timer.cancel();
    super.dispose();
  }
}
