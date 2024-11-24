import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as syspaths;

class Download {
  Future<void> single(Track track) async {
    // Check if the track is already downloaded
    bool exists = await DatabaseHelper().downloadedTrackAlreadyExists(track.id);

    if (!exists) {
      await TrackMetadata().checkTrackExists(
        // Check if exists and then get the duration
        mainContext.value!,
        track.id,
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
                Uri.parse(
                    "${AppConstants.SERVER_URL}download_track/${track.id}"),
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
                final audioFile = File('${appDir.path}/${track.id}.m4a');
                audioFile.writeAsBytesSync(audio);

                // Get the cover image
                Uint8List? image;

                final imageUrl = track.album != null
                    ? calculateBestImageForTrack(track.album!.images)
                    : null;

                final imageFile = File('${appDir.path}/${track.id}.png');

                if (imageUrl != null) {
                  final response = await http.get(Uri.parse(imageUrl));

                  image = response.bodyBytes;

                  imageFile.writeAsBytesSync(image);
                }

                // Save track metadata to db
                await DatabaseHelper().insertDownloadedTrack(
                  track.id,
                  audioFile.path,
                  track.artists.map((artist) => artist.toJson()).toList(),
                  track.name,
                  (duration * 1000).toInt(),
                  imageFile.path,
                );

                Notifications().showSpecialNotification(
                    searchScreenContext.value!,
                    "Success",
                    "Successfully donwloaded the track",
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
      Notifications().showSpecialNotification(searchScreenContext.value!,
          "Notification", "Already downloaded", AppIcons.download);
    }
  }
}
