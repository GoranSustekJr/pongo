import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as syspaths;

class Download {
  Future<void> singleWithoutAPI(String stid, Uint8List audio, double duration,
      String? imageUrl, String name, List<Map<String, dynamic>> artists) async {
    bool exists = await DatabaseHelper().downloadedTrackAlreadyExists(stid);

    if (!exists) {
      // Save to directory
      final appDir = await syspaths.getApplicationDocumentsDirectory();
      final audioFile = File('${appDir.path}/$stid.m4a');
      audioFile.writeAsBytesSync(audio);

      // Get the cover image
      Uint8List? image;
      final appDir2 = await syspaths.getApplicationDocumentsDirectory();
      final imageFile = File('${appDir2.path}/$stid.png');
      if (imageUrl != null) {
        final response = await http.get(Uri.parse(imageUrl));

        image = response.bodyBytes;

        imageFile.writeAsBytesSync(image);
      }

      // Save track metadata to db
      await DatabaseHelper().insertDownloadedTrack(
        stid,
        audioFile.path,
        artists,
        name,
        (duration * 1000).toInt(),
        imageFile.path,
      );
    }
  }

  Future<void> single(dynamic track) async {
    try {
      String id = ""; // track id
      List<Map<String, dynamic>> artists = []; // artists
      String? imageUrl = ""; // track image
      String name = ""; // track name

      if (track.runtimeType == Track) {
        id = track.id;

        artists = ((track.artists as List<ArtistTrack>)
            .map((artist) => {"id": artist.id, "name": artist.name})
            .toList());
        imageUrl = track.album != null
            ? calculateBestImageForTrack(track.album!.images)
            : null;
        name = track.name;
      } else if (track.runtimeType == MediaItem) {
        id = track.id.split('.')[2];
        artists = (jsonDecode(track.extras!["artists"]) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        imageUrl = track.artUri?.toString();
        name = track.title;
      }

      // Check if the track is already downloaded
      bool exists = await DatabaseHelper().downloadedTrackAlreadyExists(id);

      if (!exists) {
        await TrackMetadata().checkTrackExists(
          // Check if exists and then get the duration
          mainContext.value!,
          id,
          (_) {},
          (_) {},
          (duration) async {
            int tries = 0;

            // Get the track audio
            try {
              while (tries < 2) {
                tries++;
                final accessTokenHandler =
                    Provider.of<AccessToken>(mainContext.value!, listen: false);

                final response = await http.post(
                  Uri.parse("${AppConstants.SERVER_URL}download_track/$id"),
                  headers: {'Connection': 'keep-alive'},
                  body: jsonEncode(
                    {
                      "at+JWT": accessTokenHandler.accessToken,
                    },
                  ),
                );

                if (response.statusCode == 200) {
                  // If successful request
                  final audio = response.bodyBytes;

                  // if audio not null
                  // Save to directory
                  final appDir =
                      await syspaths.getApplicationDocumentsDirectory();
                  final audioFile = File('${appDir.path}/$id.m4a');
                  audioFile.writeAsBytesSync(audio);

                  // Get the cover image
                  Uint8List? image;

                  final appDir2 =
                      await syspaths.getApplicationDocumentsDirectory();
                  final imageFile = File('${appDir2.path}/$id.png');

                  if (imageUrl != null) {
                    final response = await http.get(Uri.parse(imageUrl));

                    image = response.bodyBytes;

                    imageFile.writeAsBytesSync(image);
                  }

                  // Save track metadata to db
                  await DatabaseHelper().insertDownloadedTrack(
                    id,
                    audioFile.path,
                    artists,
                    name,
                    (duration * 1000).toInt(),
                    imageFile.path,
                  );

                  Notifications().showSpecialNotification(
                      notificationsContext.value!,
                      AppLocalizations.of(notificationsContext.value!)!
                          .successful,
                      AppLocalizations.of(notificationsContext.value!)!
                          .successfullydownloadedthetrack,
                      AppIcons.download);

                  tries++;
                } else if (response.statusCode == 401) {
                  if (tries < 2) {
                    await AccessTokenhandler().renew(mainContext.value)!;
                  } else {
                    break; // Exit the loop after the second attempt
                  }
                } else if (response.statusCode == 403) {
                  Notifications().showSpecialNotification(
                      notificationsContext.value!,
                      AppLocalizations.of(notificationsContext.value!)!.error,
                      AppLocalizations.of(notificationsContext.value!)!
                          .premiumisneededtodownloadatrack,
                      AppIcons.warning, onTap: () {
                    if (!premium.value) {
                      navigationBarIndex.value = 2;
                      currentTrackHeight.value = 0;
                    }
                  });
                } else {
                  return {}; // Handle other status codes as needed
                }
              }
            } catch (e) {
              //print(e);

              return {};
            }
            return {};
          },
        );
      } else {
        Notifications().showSpecialNotification(
            notificationsContext.value!,
            AppLocalizations.of(notificationsContext.value!)!.notification,
            AppLocalizations.of(notificationsContext.value!)!
                .trackalreadydownloaded,
            AppIcons.download);
      }
    } catch (e) {
      Notifications().showWarningNotification(notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!)!.downloadfailed);
      //print(e);
    }
  }

  Future<Map> playlist(BuildContext context, List<String> stids) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}download_a_playlist"),
          headers: {'Connection': 'keep-alive'},
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "stids": stids,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);

          return data;
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
          }
        } else if (response.statusCode == 403) {
          Notifications().showSpecialNotification(
            notificationsContext.value!,
            AppLocalizations.of(notificationsContext.value!)!.error,
            AppLocalizations.of(notificationsContext.value!)!
                .premiumisneededtodownloadatrack,
            AppIcons.warning,
            onTap: () {
              if (!premium.value) {
                navigationBarIndex.value = 2;
                currentTrackHeight.value = 0;
              }
            },
          );
          return {};
        } else {
          return {}; // Handle other status codes as needed
        }
      }
    } catch (e) {
      //print(e);
      return {};
    }
    return {};
  }
}
