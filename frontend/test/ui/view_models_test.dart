import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/domain/models/catalog/catalog_results.dart';
import 'package:pongo/domain/models/playlists/playlist_handler.dart';
import 'package:pongo/domain/models/playlists/user_playlist.dart';
import 'package:pongo/domain/models/settings/app_settings.dart';
import 'package:pongo/domain/models/sleep_alarm/sleep_alarm.dart';
import 'package:pongo/ui/core/messages/app_message.dart';
import 'package:pongo/ui/core/messages/message_center.dart';
import 'package:pongo/ui/core/view_models/track_actions_view_model.dart';
import 'package:pongo/ui/library/view_models/locals_view_model.dart';
import 'package:pongo/ui/playlists/view_models/user_playlists_view_model.dart';
import 'package:pongo/ui/recommendations/view_models/recommendations_view_model.dart';
import 'package:pongo/ui/search/view_models/search_history_view_model.dart';
import 'package:pongo/ui/sleep_alarm/view_models/sleep_alarm_view_model.dart';

import '../fakes/fake_repositories.dart';

/// Lets the work a view model starts in its constructor finish.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('RecommendationsViewModel', () {
    test('loads the feed for the saved market and history', () async {
      final catalog = FakeCatalogRepository()
        ..feed = HomeFeed(topTracks: [fakeTrack('1')]);
      final history = FakeHistoryRepository()..played.addAll(['7', '8']);
      final viewModel = RecommendationsViewModel(
        catalog: catalog,
        history: history,
        settings: FakeSettingsRepository(const AppSettings(market: 'HR')),
      );
      await settle();

      expect(viewModel.showBody, isTrue);
      expect(viewModel.failed, isFalse);
      expect(viewModel.topTracks.single.id, '1');
      expect(catalog.lastHomeFeed?.market, 'HR');
      expect(catalog.lastHomeFeed?.history, ['7', '8']);
    });

    test('reports a failed load', () async {
      final viewModel = RecommendationsViewModel(
        catalog: FakeCatalogRepository()..feed = null,
        history: FakeHistoryRepository(),
        settings: FakeSettingsRepository(),
      );
      await settle();

      expect(viewModel.showBody, isTrue);
      expect(viewModel.failed, isTrue);
    });

    test('skips the request when both sections are turned off', () async {
      final catalog = FakeCatalogRepository();
      final viewModel = RecommendationsViewModel(
        catalog: catalog,
        history: FakeHistoryRepository(),
        settings: FakeSettingsRepository(
          const AppSettings(enableHistory: false, enableCategories: false),
        ),
      );
      await settle();

      expect(viewModel.showBody, isTrue);
      expect(catalog.lastHomeFeed, isNull);
    });
  });

  group('SearchHistoryViewModel', () {
    test('keeps searches newest first without duplicates', () async {
      final viewModel = SearchHistoryViewModel(
        history: FakeHistoryRepository(),
      );
      await viewModel.add('a');
      await viewModel.add('b');
      await viewModel.add('a');
      expect(viewModel.searches, ['a', 'b']);

      await viewModel.remove('a');
      expect(viewModel.searches, ['b']);

      await viewModel.clear();
      expect(viewModel.searches, isEmpty);
    });
  });

  group('LocalsViewModel', () {
    late FakeDownloadsRepository downloads;
    late FakeSettingsRepository settings;
    late FakePlayerRepository player;

    setUp(() {
      downloads = FakeDownloadsRepository()
        ..items.addAll([
          DownloadedTrack(
            track: fakeTrack('1', name: 'Beta'),
            durationMilliseconds: 1000,
            rowId: 1,
          ),
          DownloadedTrack(
            track: fakeTrack('2', name: 'Alpha', artist: 'Zed'),
            durationMilliseconds: 2000,
            rowId: 2,
          ),
        ]);
      settings = FakeSettingsRepository(
        const AppSettings(localsSort: LocalsSort.titleAscending),
      );
      player = FakePlayerRepository();
    });

    LocalsViewModel create() => LocalsViewModel(
      downloads: downloads,
      settings: settings,
      player: player,
    );

    test('sorts the downloads and remembers a new order', () async {
      final viewModel = create();
      await settle();
      expect(viewModel.tracks.map((track) => track.name), ['Alpha', 'Beta']);

      await viewModel.sort(LocalsSort.firstAdded);
      expect(viewModel.tracks.map((track) => track.id), ['1', '2']);
      expect(settings.settings.localsSort, LocalsSort.firstAdded);
    });

    test('filters by title, then by artist', () async {
      final viewModel = create();
      await settle();

      viewModel.onSearched('zed');
      expect(viewModel.tracks.single.id, '2');

      viewModel.onSearched('');
      expect(viewModel.tracks, hasLength(2));
    });

    test('plays the downloads as one collection', () async {
      final viewModel = create();
      await settle();
      await viewModel.shuffle();

      expect(player.plays.single.collectionId, LocalsViewModel.collectionId);
      expect(player.plays.single.shuffle, isTrue);
    });

    test('deletes the selection and reloads', () async {
      final viewModel = create();
      await settle();
      viewModel.select('1');
      await viewModel.removeSelected();

      expect(viewModel.tracks.single.id, '2');
      expect(viewModel.selectedTracks, isEmpty);
      expect(viewModel.edit, isFalse);
    });
  });

  group('UserPlaylistsViewModel', () {
    test('lists and deletes playlists of its type', () async {
      final playlists = FakePlaylistRepository()
        ..online.addAll(const [
          UserPlaylist(id: 1, title: 'One'),
          UserPlaylist(id: 2, title: 'Two'),
        ])
        ..local.add(const UserPlaylist(id: 9, title: 'Local'));
      final viewModel = UserPlaylistsViewModel(
        type: PlaylistHandlerType.online,
        playlists: playlists,
      );
      await settle();
      expect(viewModel.playlists.map((playlist) => playlist.title), [
        'One',
        'Two',
      ]);

      await viewModel.remove(0);
      expect(viewModel.playlists.single.id, 2);
      expect(viewModel.playlistsLength, 1);
      expect(playlists.online.single.id, 2);
      expect(playlists.local, hasLength(1));
    });
  });

  group('TrackActionsViewModel', () {
    test('toggles a favourite and tells the user', () async {
      final messages = MessageCenter();
      final shown = <AppMessage>[];
      messages.messages.listen(shown.add);
      final favourites = FakeFavouritesRepository();
      final viewModel = TrackActionsViewModel(
        favourites: favourites,
        downloads: FakeDownloadsRepository(),
        player: FakePlayerRepository(),
        messages: messages,
      );

      await viewModel.toggleFavourite(fakeTrack('5'));
      expect(await viewModel.isFavourite('5'), isTrue);
      await viewModel.toggleFavourite(fakeTrack('5'));
      expect(await viewModel.isFavourite('5'), isFalse);
      await settle();

      expect(shown, hasLength(2));
      expect(shown, everyElement(isA<InfoMessage>()));
    });
  });

  group('SleepAlarmViewModel', () {
    late FakePlayerRepository player;
    late MessageCenter messages;
    late List<AppMessage> shown;
    late SleepAlarmViewModel viewModel;

    setUp(() async {
      player = FakePlayerRepository();
      messages = MessageCenter();
      shown = [];
      messages.messages.listen(shown.add);
      viewModel = SleepAlarmViewModel(
        alarms: FakeSleepAlarmRepository(),
        player: player,
        settings: FakeSettingsRepository(),
        messages: messages,
      );
      await settle();
      await viewModel.add(const SleepAlarm(id: -1));
    });

    test('refuses to start an alarm with an empty queue', () async {
      await viewModel.changeActiveSleepAlarm(0);
      await settle();

      expect(player.alarms, isEmpty);
      expect(shown.single, isA<ErrorMessage>());
    });

    test('starts an alarm and stops it when it is deleted', () async {
      player.queue.value = [const MediaItem(id: 'search.single.1', title: 'x')];
      await viewModel.changeActiveSleepAlarm(0);
      expect(viewModel.activeAlarm, viewModel.sleepAlarms.single.id);

      await viewModel.removeSleepAlarm(0);
      expect(viewModel.activeAlarm, -1);
      expect(viewModel.sleepAlarms, isEmpty);
      expect(player.alarms.last, isNull);
    });

    test('saves the alarm volume in the settings', () async {
      await viewModel.updateSleepAlarmDeviceVolume(0.4);
      expect(viewModel.deviceVolume, 0.4);
    });
  });
}
