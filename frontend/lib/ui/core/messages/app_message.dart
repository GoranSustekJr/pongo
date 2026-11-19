import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

/// Localized text, resolved when the message is shown.
typedef LocalizedText = String Function(AppLocalizations l10n);

/// A notification for the user, posted by a view model.
sealed class AppMessage {
  const AppMessage();
}

/// A confirmation or piece of information with an icon.
final class InfoMessage extends AppMessage {
  /// Creates an info message.
  const InfoMessage({
    required this.title,
    required this.body,
    required this.icon,
    this.iconColor,
  });

  /// The heading.
  final LocalizedText title;

  /// The text.
  final LocalizedText body;

  /// The icon shown beside the text.
  final IconData icon;

  /// The icon color, white if `null`.
  final Color? iconColor;
}

/// A warning about something the user should know.
final class WarningMessage extends AppMessage {
  /// Creates a warning.
  const WarningMessage(this.body);

  /// The text.
  final LocalizedText body;
}

/// A failure.
final class ErrorMessage extends AppMessage {
  /// Creates an error message.
  const ErrorMessage({required this.title, required this.body});

  /// The heading.
  final LocalizedText title;

  /// The text.
  final LocalizedText body;
}

/// The server disabled the account.
final class AccountDisabledMessage extends AppMessage {
  /// Creates an account disabled message.
  const AccountDisabledMessage();
}

/// Shazam recognized a song.
final class ShazamMessage extends AppMessage {
  /// Creates a message for the recognized song.
  const ShazamMessage({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  /// The song title.
  final String title;

  /// The artist.
  final String subtitle;

  /// URL of the cover art.
  final String imageUrl;
}
