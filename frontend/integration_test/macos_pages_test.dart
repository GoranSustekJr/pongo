// Opens every page of the Mac window and reports layout errors. Needs a
// signed in Mac: flutter test integration_test/macos_pages_test.dart -d macos
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pongo/main.dart' as app;
import 'package:pongo/ui/shell/view_models/shell_view_model.dart';
import 'package:pongo/ui/shell/widgets/desktop/home_macos.dart';
import 'package:provider/provider.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('every Mac page lays out', (tester) async {
    final errors = <String>[];
    await app.main();
    final shellFinder = find.byType(MainMacos);
    final signedIn = await pumpUntil(
      tester,
      () => shellFinder.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 40),
    );
    expect(signedIn, isTrue, reason: 'sign in on the Mac first');

    // Collected after start up, so only the pages' own errors count
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString().split('\n').first);
      previous?.call(details);
    };

    final shell = tester.element(shellFinder).read<ShellViewModel>();
    const pages = {
      0: 'home',
      1: 'favourites',
      2: 'online_playlists',
      3: 'offline_songs',
      4: 'offline_playlists',
      5: 'sleep',
      6: 'lyrics',
      7: 'settings',
    };
    for (final MapEntry(key: index, value: name) in pages.entries) {
      shell.navigationBarIndex.value = index;
      await tester.pump(const Duration(seconds: 4));
      await saveScreenshot(tester, name);
      print('PAGE $name errors=${errors.length}');
    }
    FlutterError.onError = previous;
    for (final error in errors.toSet()) {
      print('PAGE ERROR $error');
    }
    expect(errors, isEmpty);
  });
}
