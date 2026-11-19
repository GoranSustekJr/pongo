import 'dart:async';

import 'app_message.dart';

/// Delivers [AppMessage]s from view models to the widget that shows them.
class MessageCenter {
  final _messages = StreamController<AppMessage>.broadcast();

  /// The posted messages.
  Stream<AppMessage> get messages => _messages.stream;

  /// Posts [message] to be shown.
  void show(AppMessage message) => _messages.add(message);

  /// Closes the stream.
  Future<void> dispose() => _messages.close();
}
