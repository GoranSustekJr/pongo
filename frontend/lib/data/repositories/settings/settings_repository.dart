import 'package:flutter/foundation.dart';

import '../../../domain/models/settings/app_settings.dart';

/// Source of truth for the user's preferences.
abstract class SettingsRepository extends ChangeNotifier {
  /// The current preferences.
  AppSettings get settings;

  /// Loads the saved preferences. Call once before reading [settings].
  Future<void> load();

  /// Saves [settings] and notifies listeners.
  Future<void> save(AppSettings settings);

  /// Saves the preferences returned by [change] for the current ones.
  Future<void> update(AppSettings Function(AppSettings current) change) =>
      save(change(settings));
}
