import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/messages/message_center.dart';
import '../../core/view_models/track_actions_view_model.dart';
import '../../player/view_models/player_view_model.dart';
import '../../shell/view_models/shell_view_model.dart';
import 'app_settings_view_model.dart';
import 'connectivity_view_model.dart';
import 'session_view_model.dart';

/// View models that live as long as the app, above every screen.
///
/// They need the repositories from `createProviders` above them.
final List<SingleChildWidget> appViewModelProviders = [
  Provider(
    create: (_) => MessageCenter(),
    dispose: (_, center) => center.dispose(),
  ),
  ChangeNotifierProvider(
    create: (context) => AppSettingsViewModel(repository: context.read()),
  ),
  ChangeNotifierProvider(
    create: (context) => ConnectivityViewModel(connectivity: context.read()),
  ),
  ChangeNotifierProvider(
    create: (context) => SessionViewModel(
      authRepository: context.read(),
      messages: context.read(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        ShellViewModel(catalog: context.read(), messages: context.read()),
  ),
  ChangeNotifierProvider(
    lazy: false,
    create: (context) => PlayerViewModel(
      player: context.read(),
      history: context.read(),
      settings: context.read(),
      blurhash: context.read(),
      messages: context.read(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) => TrackActionsViewModel(
      favourites: context.read(),
      downloads: context.read(),
      player: context.read(),
      messages: context.read(),
    ),
  ),
];
