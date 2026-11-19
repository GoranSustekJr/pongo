import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/data/repositories/lyrics/lyrics_repository.dart';
import 'package:pongo/data/repositories/player/media_items.dart';
import 'package:pongo/data/repositories/player/player_repository.dart';
import 'package:pongo/data/repositories/settings/settings_repository.dart';
import 'package:pongo/data/services/device/connectivity_service.dart';
import 'package:pongo/data/services/device/volume_service.dart';
import 'package:pongo/data/services/media/blurhash_service.dart';
import 'package:pongo/domain/models/catalog/track.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/ui/app/view_models/app_settings_view_model.dart';
import 'package:pongo/ui/core/messages/message_center.dart';
import 'package:pongo/ui/core/themes/theme.dart';
import 'package:pongo/ui/core/view_models/track_actions_view_model.dart';
import 'package:pongo/ui/player/view_models/player_view_model.dart';
import 'package:pongo/ui/player/widgets/phone/playing_details/playing_details_phone.dart';
import 'package:pongo/ui/shell/view_models/shell_view_model.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_repositories.dart';

class _PlayingPlayer extends FakePlayerRepository {
  _PlayingPlayer(MediaItem item) {
    currentItem.value = item;
    queue.value = [item];
  }

  @override
  Stream<PlaybackState> get playbackState =>
      Stream.value(PlaybackState(playing: true));
  @override
  Stream<Duration> get positionStream => Stream.value(Duration.zero);
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration> get bufferedPositionStream => Stream.value(Duration.zero);
  @override
  Stream<Duration?> get durationStream =>
      Stream.value(const Duration(minutes: 3));
  @override
  Stream<LoopMode> get loopModeStream => Stream.value(LoopMode.off);
  @override
  LoopMode get loopMode => LoopMode.off;
  @override
  Stream<bool> get shuffleEnabledStream => Stream.value(false);
  @override
  Stream<List<int>> get shuffleIndicesStream => Stream.value(const [0]);
  @override
  List<int> get shuffleIndices => const [0];
  @override
  Stream<double> get volumeStream => Stream.value(1);
  @override
  int? get currentIndex => 0;
  @override
  bool get isPlaying => true;
  @override
  ValueListenable<bool> get canShuffle => ValueNotifier(true);
  @override
  ValueListenable<bool> get queueMatchesCollection => ValueNotifier(true);
  @override
  Stream<List<MediaItem>> get queueStream => Stream.value(queue.value);
}

class _FakeLyrics implements LyricsRepository {
  @override
  Future<Lyrics> lyrics({
    required String name,
    required String artist,
    required String album,
    required Duration duration,
  }) async => (plain: 'one\ntwo', synced: '[00:01.00] one\n[00:02.00] two');
  @override
  Future<int> syncDelay(String stid) async => 0;
  @override
  Future<void> saveSyncDelay(String stid, int milliseconds) async {}
}

/// Opens the playing details while [track] plays from [collectionId], and
/// fails on any exception thrown while building them.
Future<void> pumpDetails(
  WidgetTester tester,
  Track track, {
  required String collectionId,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final item = mediaItemFor(
    track,
    collectionId: collectionId,
    duration: const Duration(minutes: 3),
  );
  final player = _PlayingPlayer(item);
  final settings = FakeSettingsRepository();
  final history = FakeHistoryRepository();
  final messages = MessageCenter();
  final shell = ShellViewModel(
    catalog: FakeCatalogRepository(),
    messages: messages,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: messages),
        Provider<PlayerRepository>.value(value: player),
        Provider<LyricsRepository>.value(value: _FakeLyrics()),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
        Provider.value(value: ConnectivityService()),
        Provider.value(value: VolumeService()),
        ChangeNotifierProvider(
          create: (_) => AppSettingsViewModel(repository: settings),
        ),
        ChangeNotifierProvider.value(value: shell),
        ChangeNotifierProvider(
          create: (_) => PlayerViewModel(
            player: player,
            history: history,
            settings: settings,
            blurhash: BlurhashService(),
            messages: messages,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TrackActionsViewModel(
            favourites: FakeFavouritesRepository(),
            downloads: FakeDownloadsRepository(),
            player: player,
            messages: messages,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayingDetailsPhone(showAlbum: (_) {}, showArtist: (_) {}),
        ),
      ),
    ),
  );
  shell.currentTrackHeight.value = 844;
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
  expect(find.text('Song', skipOffstage: false), findsWidgets);
}

void main() {
  testWidgets('opens the playing details of a track', (tester) async {
    await pumpDetails(
      tester,
      Track(
        id: 'abc123',
        name: 'Song',
        artists: const [ArtistTrack(id: '1', name: 'Artist')],
        album: const AlbumTrack(
          id: 'al1',
          name: 'Album',
          images: [],
          releaseDate: '2020-01-01',
        ),
      ),
      collectionId: 'recommended.single',
    );
  });

  testWidgets('opens the playing details of a downloaded track', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      const Track(
        id: 'abc123',
        name: 'Song',
        artists: [ArtistTrack(id: '1', name: 'Artist')],
        album: null,
        type: TrackType.offline,
        audio: '/tmp/abc123.mp3',
      ),
      collectionId: 'library.locals',
    );
  });
}
