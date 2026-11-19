// A diagnostic probe whose output is read from the test log.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:pongo/main.dart' as app;
import 'package:pongo/ui/recommendations/widgets/phone/recommendations_phone.dart';
import 'package:pongo/ui/shell/view_models/shell_view_model.dart';
import 'package:provider/provider.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('probe', (tester) async {
    await app.main();
    final field = find.byType(GlassTextField);
    final up = await pumpUntil(
      tester,
      () => field.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 40),
    );
    print('PROBE signedInHome=$up');
    if (!up) return;
    await tester.pump(const Duration(seconds: 4));
    await saveScreenshot(tester, 'home');
    final r = tester.getRect(field.first);
    print('PROBE bar=$r');
    final shell = tester.element(field.first).read<ShellViewModel>();
    final node = shell.searchFocusNode;
    final searchBarIsSearching = shell.searchBarIsSearching;
    final points = {
      'center': r.center,
      'icon': r.centerLeft + const Offset(20, 0),
      'leftEdge': r.centerLeft + const Offset(5, 0),
      'right': r.centerRight - const Offset(20, 0),
      'top': r.topCenter + const Offset(0, 3),
      'bottom': r.bottomCenter - const Offset(0, 3),
    };
    for (final e in points.entries) {
      node.unfocus();
      searchBarIsSearching.value = false;
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(e.value);
      await tester.pump(const Duration(milliseconds: 700));
      print('PROBE tap ${e.key} focused=${node.hasFocus}');
    }
    await saveScreenshot(tester, 'focused');
    await tester.enterText(field.first, 'Severina');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 5));
    await saveScreenshot(tester, 'results');
    final cancel = find.byType(GlassButton);
    print(
      'PROBE afterSubmit searching=${searchBarIsSearching.value} focused=${node.hasFocus} cancelShown=${cancel.evaluate().isNotEmpty}',
    );
    await tester.tap(cancel.first);
    await tester.pump(const Duration(seconds: 2));
    final reco = tester.getTopLeft(find.byType(RecommendationsPhone));
    print(
      'PROBE afterCancel searching=${searchBarIsSearching.value} text="${tester.widget<GlassTextField>(field.first).controller?.text}" recoTop=${reco.dy} cancelShown=${cancel.evaluate().isNotEmpty}',
    );
    await tester.pump(const Duration(seconds: 2));
    await saveScreenshot(tester, 'cancelled');
  });
}
