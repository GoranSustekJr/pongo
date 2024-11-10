import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class Notifications {
  // Common method for showing a notification
  showNotification({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Color backgroundColor = Colors.black54, // Default background color
    int durationInSeconds = 5, // Default duration
    int maxLines = 3, // Max lines for text
  }) {
    InAppNotification.show(
      context: context,
      duration: Duration(seconds: durationInSeconds),
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 25,
                      ),
                      razw(10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              message,
                              style: const TextStyle(),
                              textAlign: TextAlign.left,
                              maxLines: maxLines,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show warning notification
  void showWarningNotification(BuildContext context, String message) {
    showNotification(
      context: context,
      title: AppLocalizations.of(context)!.warning,
      message: message,
      icon: CupertinoIcons.exclamationmark_triangle,
      backgroundColor: Col.primaryCard,
      durationInSeconds: 5,
    );
  }

  // Show custom notification with title and icon
  void showSpecialNotification(
      BuildContext context, String title, String message, IconData icon) {
    showNotification(
      context: context,
      title: title,
      message: message,
      icon: icon,
      backgroundColor: Col.primaryCard,
      durationInSeconds: 5,
    );
  }
}
