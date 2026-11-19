import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/settings/app_settings.dart';

/// Exposes the user's preferences to every screen.
class AppSettingsViewModel extends ChangeNotifier {
  /// Creates a view model for [_repository].
  AppSettingsViewModel({required this._repository}) {
    _repository.addListener(notifyListeners);
  }

  final SettingsRepository _repository;

  /// The current preferences.
  AppSettings get settings => _repository.settings;

  /// Saves the preferences returned by [change].
  Future<void> update(AppSettings Function(AppSettings current) change) =>
      _repository.update(change);

  @override
  void dispose() {
    _repository.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Access to the preferences from widgets.
extension AppSettingsContext on BuildContext {
  /// The preferences, rebuilding this widget when they change.
  ///
  /// Use [readSettings] outside of `build`.
  AppSettings get settings => watch<AppSettingsViewModel>().settings;

  /// The preferences, without listening for changes.
  AppSettings get readSettings => read<AppSettingsViewModel>().settings;
}
