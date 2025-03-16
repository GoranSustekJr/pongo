import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class Shazam {
  Future<void> shazamIt(context, String stid) async {
    int tries = 0;
    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse(
              "${AppConstants.SERVER_URL}6a2f5d49dda86647d136751f354f0bbfbd76a414a283b18f211b34f911029e0e"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "stid": stid,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          Notifications().showShazamNotification(
            notificationsContext.value!,
            data["track"]["title"],
            data["track"]["subtitle"],
            data["track"]["images"]["coverart"],
          );
          break;
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
          }
        } else {
          Notifications().showErrorNotification(
              notificationsContext.value!,
              AppLocalizations.of(notificationsContext.value!)!.error,
              AppLocalizations.of(notificationsContext.value!)!
                  .shazamfailed); // Handle other status codes as needed
        }
      }
    } catch (e) {
      //print(e);
      Notifications().showErrorNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!)!.error,
          AppLocalizations.of(notificationsContext.value!)!
              .shazamfailed); // Handle other status codes as needed
    }
  }
}
