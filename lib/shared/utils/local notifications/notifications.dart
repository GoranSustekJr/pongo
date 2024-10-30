import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class Notifications {
  showWarningNotification(context, String message) {
    // Warning notification

    InAppNotification.show(
      context: context,
      duration: const Duration(seconds: 5),
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
                  color: Col.primaryCard.withAlpha(50),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 25,
                      ),
                      razw(10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.warning,
                              style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 12),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              message,
                              style: const TextStyle(),
                              textAlign: TextAlign.left,
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

  showSpecialNotification(
      context, String title, String message, IconData icon) {
    // Warning notification

    InAppNotification.show(
      context: context,
      duration: const Duration(seconds: 5),
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
                  color: Col.primaryCard.withAlpha(50),
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
                                  fontSize: 12),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              message,
                              style: const TextStyle(),
                              textAlign: TextAlign.left,
                              maxLines: 3,
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
}
