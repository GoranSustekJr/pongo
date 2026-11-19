import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../notifications.dart';
import 'app_message.dart';
import 'message_center.dart';

/// Shows the messages posted to the [MessageCenter] as in-app notifications.
class MessageListener extends StatefulWidget {
  /// Shows messages above [child].
  const MessageListener({super.key, required this.child});

  /// The content below the notifications.
  final Widget child;

  @override
  State<MessageListener> createState() => _MessageListenerState();
}

class _MessageListenerState extends State<MessageListener> {
  StreamSubscription<AppMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<MessageCenter>().messages.listen(_show);
  }

  void _show(AppMessage message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final notifications = Notifications();
    switch (message) {
      case InfoMessage(
        :final title,
        :final body,
        :final icon,
        :final iconColor,
      ):
        notifications.showSpecialNotification(
          context,
          title(l10n),
          body(l10n),
          icon,
          iconColor: iconColor ?? Colors.white,
        );
      case WarningMessage(:final body):
        notifications.showWarningNotification(context, body(l10n));
      case ErrorMessage(:final title, :final body):
        notifications.showErrorNotification(context, title(l10n), body(l10n));
      case AccountDisabledMessage():
        notifications.showDisabledNotification(context);
      case ShazamMessage(:final title, :final subtitle, :final imageUrl):
        notifications.showShazamNotification(
          context,
          title,
          subtitle,
          imageUrl,
        );
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
