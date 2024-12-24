import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as syspaths;

class Download {
  Future<void> single(dynamic track) async {
    String id = ""; // track id
    List<Map<String, dynamic>> artists = []; // artists
    String? imageUrl = ""; // track image
    String name = ""; // track name

    if (track.runtimeType == Track) {
      id = track.id;
      print(track.artists.runtimeType);
      artists = (track.artists as List<ArtistTrack>)
          .map((artist) => artist.toJson())
          .toList();
      imageUrl = track.album != null
          ? calculateBestImageForTrack(track.album!.images)
          : null;
      name = track.name;
    } else if (track.runtimeType == MediaItem) {
      id = track.id.split('.')[2];
      artists = track.artist
          .split(', ')
          .map<Map<String, dynamic>>(
              (artist) => ArtistTrack(id: "", name: artist).toJson())
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
              print("FDJALSKFJ; $tries");
              final response = await http.post(
                Uri.parse("${AppConstants.SERVER_URL}download_track/$id"),
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
              } else {
                return {}; // Handle other status codes as needed
              }
            }
          } catch (e) {
            print(e);

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
  }
}
