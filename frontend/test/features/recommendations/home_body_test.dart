import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/services/media/blurhash_service.dart';
import 'package:pongo/domain/models/catalog/album.dart';
import 'package:pongo/domain/models/catalog/artist.dart';
import 'package:pongo/domain/models/catalog/catalog_results.dart';
import 'package:pongo/domain/models/catalog/playlist.dart';
import 'package:pongo/domain/models/catalog/track.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/ui/app/view_models/app_settings_view_model.dart';
import 'package:pongo/ui/core/messages/message_center.dart';
import 'package:pongo/ui/core/themes/theme.dart';
import 'package:pongo/ui/core/view_models/track_actions_view_model.dart';
import 'package:pongo/ui/player/view_models/player_view_model.dart';
import 'package:pongo/ui/recommendations/view_models/recommendations_view_model.dart';
import 'package:pongo/ui/recommendations/widgets/phone/recommendations_body_phone.dart';
import 'package:pongo/ui/shell/view_models/shell_view_model.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_repositories.dart';

Track track(int i) =>
    fakeTrack('$i', name: 'Šuštek track with a rather long name $i');

Future<void> pumpHome(WidgetTester tester, List<Track> history) async {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone 14
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final catalog = FakeCatalogRepository()
    ..feed = HomeFeed(
      history: history,
      topTracks: [track(100), track(101)],
      topArtists: const [Artist(id: '1', name: 'Popular artist', image: '')],
      topPlaylists: const [Playlist(id: '1', name: 'Deezer Hits', image: '')],
      newReleases: const [
        Album(
          id: '1',
          name: 'New album',
          type: 'album',
          artists: ['Artist'],
          image: '',
        ),
      ],
    );
  final settings = FakeSettingsRepository();
  final historyRepository = FakeHistoryRepository();
  final player = FakePlayerRepository();
  final messages = MessageCenter();
  final viewModel = RecommendationsViewModel(
    catalog: catalog,
    history: historyRepository,
    settings: settings,
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: messages),
        ChangeNotifierProvider(
          create: (_) => AppSettingsViewModel(repository: settings),
        ),
        ChangeNotifierProvider(
          create: (_) => ShellViewModel(catalog: catalog, messages: messages),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerViewModel(
            player: player,
            history: historyRepository,
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
        home: Scaffold(body: RecommendationsBodyPhone(dataManager: viewModel)),
      ),
    ),
  );
}

void main() {
  testWidgets('shows every section without overflowing', (tester) async {
    await pumpHome(tester, List.generate(8, track));

    final scrollable = find.byType(Scrollable).first;
    for (final title in [
      'Last listened to',
      'Top tracks',
      'Popular artists',
      'Featured playlists',
      'New releases',
    ]) {
      await tester.dragUntilVisible(
        find.text(title),
        scrollable,
        const Offset(0, -200),
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent tracks are not repeated below the quick picks', (
    tester,
  ) async {
    await pumpHome(tester, List.generate(6, track));

    expect(find.text('Last listened to'), findsNothing);
    expect(find.textContaining('Šuštek track'), findsWidgets);
  });
}
