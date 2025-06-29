import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:in_app_notification_desktop/in_app_notification.dart' as iand;
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

class Notifications {
  // Common method for showing a notification
  showNotification({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Color backgroundColor = Colors.black54, // Default background color
    int durationInSeconds = 5, // Default duration
    int maxLines = 5, // Max lines for text
    Color iconColor = Colors.white, // Default
    void Function()? onTap,
  }) {
    if (kIsMobile) {
      InAppNotification.show(
        context: context,
        duration: Duration(seconds: durationInSeconds),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: liquidGlassLayer(
                child: liquidGlass(
                  child: liquidGlassBackground(
                    enabled: liquidGlassEnabled,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: kIsApple ? 0 : 24, sigmaY: kIsApple ? 0 : 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: kIsApple
                              ? Col.transp
                              : backgroundColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 25,
                                color: iconColor,
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
            ),
          ),
        ),
      );
    }
  }

  // Show warning notification
  void showWarningNotification(BuildContext context, String message) {
    showNotification(
      context: context,
      title: AppLocalizations.of(context).warning,
      message: message,
      icon: AppIcons.warning,
      backgroundColor: Col.prim,
      durationInSeconds: 10,
      maxLines: 10,
    );
  }

  // Show custom notification with title and icon
  void showSpecialNotification(
      BuildContext context, String title, String message, IconData icon,
      {Color iconColor = Colors.white, void Function()? onTap}) {
    showNotification(
      context: context,
      title: title,
      message: message,
      icon: icon,
      backgroundColor: Col.prim,
      durationInSeconds: 10,
      iconColor: iconColor,
      onTap: onTap,
    );
  }

  // Show error notification
  void showErrorNotification(
      BuildContext context, String title, String message) {
    showNotification(
        context: context,
        title: title,
        message: message,
        icon: AppIcons.warning);
  }

  // Show disabled notification
  void showDisabledNotification(BuildContext context) {
    showNotification(
        context: context,
        title: AppLocalizations.of(context).accountdisabled,
        message: AppLocalizations.of(context)
            .pleasecontactinordertoenableyouraccountandusetheapp,
        icon: AppIcons.warning,
        durationInSeconds: 20);
  }

  // Shazam notification
  void showShazamNotification(
    BuildContext context,
    String title,
    String subtitle,
    String image,
  ) {
    if (kIsMobile) {
      InAppNotification.show(
        context: context,
        duration: const Duration(seconds: 10),
        onTap: () {
          if (searchDataManagr.value != null) {
            currentTrackHeight.value = 0; // Close the details screen if up
            navigationBarIndex.value = 0; // Send to search screen
            // Search the name and song
            searchDataManagr.value!.search(
              "$title - $subtitle",
            );
            searchBarIsSearching.value = true; // Focus
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: liquidGlassLayer(
                child: liquidGlass(
                  child: liquidGlassBackground(
                    enabled: liquidGlassEnabled,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: kIsApple ? 0 : 24, sigmaY: kIsApple ? 0 : 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              kIsApple ? Col.transp : Col.prim.withAlpha(100),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 55,
                                width: 55,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: ImageCompatible(
                                      image: image,
                                      width: 55,
                                      height: 55,
                                    )),
                              ),
                              razw(10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17.5,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                          color: Colors.white.withAlpha(175),
                                          fontSize: 15),
                                      textAlign: TextAlign.left,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/icons/shazam.png',
                                width: 30,
                                height: 30,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      iand.InAppNotification.show(
        context: context,
        duration: const Duration(seconds: 10),
        onTap: () {
          if (!fullscreenPlaying.value) {
            if (searchDataManagr.value != null) {
              currentTrackHeight.value = 0; // Close the details screen if up
              navigationBarIndex.value = 0; // Send to search screen
              // Search the name and song
              searchDataManagr.value!.search(
                "$title - $subtitle",
              );
              searchBarIsSearching.value = true; // Focus
            }
          }
        },
        width: 500,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: liquidGlassLayer(
                child: liquidGlass(
                  child: liquidGlassBackground(
                    enabled: liquidGlassEnabled,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: kIsApple ? 0 : 24, sigmaY: kIsApple ? 0 : 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Col.prim.withAlpha(100),
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        child: SizedBox(
                          width: 500,
                          height: 150,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 95,
                                  width: 95,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ImageCompatible(
                                        image: image,
                                        width: 95,
                                        height: 95,
                                      )),
                                ),
                                razw(10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19.5,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                            color: Colors.white.withAlpha(175),
                                            fontSize: 17),
                                        textAlign: TextAlign.left,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'assets/icons/shazam.png',
                                  width: 30,
                                  height: 30,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}
