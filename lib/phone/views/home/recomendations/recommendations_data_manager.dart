import 'package:pongo/exports.dart';
import 'package:pongo/shared/models/spotify/category.dart';

class RecommendationsDataManager with ChangeNotifier {
  final BuildContext context;
  RecommendationsDataManager(this.context) {
    init();
  }

  // Show body
  bool showBody = false;

  // Failed query
  bool failed = false;

  // Bool recomendations disabled
  bool historyEnabled = true;
  bool categoriesEnabled = true;

  //

  // Categories
  List<SpCategory> categories = [];

  // History tracks
  List<Track> history = [];

  // Loading
  List<String> loading = [];

  // New releases
  List<Album> newReleases = [];

  // Init the manager
  Future<void> init() async {
    failed = false;

    // Check if user wants to get recommendations
    bool getHistory = await Storage().getEnableHistory();
    bool getCatgories = await Storage().getEnableCategories();

    historyEnabled = getHistory;
    categoriesEnabled = getCatgories;

    if (historyEnabled || categoriesEnabled) {
      final data = await Recommendations().get(context);

      if (data.isNotEmpty) {
        // Set the categories
        categories =
            SpCategory.fromMapList(data["categories"]["categories"]["items"]);

        // Set the history
        if (data["history"] != null) {
          history = Track.fromMapList(data["history"]["tracks"]);
        }

        if (data["new_releases"] != null) {
          newReleases =
              (data["new_releases"]["albums"]["items"] as List<dynamic>)
                  .map((album) {
            return Album(
              id: album["id"],
              name: album["name"],
              type: album["album_type"],
              artists: album["artists"].map((artist) {
                return artist["name"]; //{artist["id"]: artist["name"]};
              }).toList(),
              image: calculateWantedResolution(album["images"], 300, 300),
            );
          }).toList();
        }
      } else {
        failed = true;
      }
    }

    showBody = true;

    notifyListeners();
  }

  // Loading add stid
  void loadingAdd(String stid) {
    if (!loading.contains(stid)) {
      loading.add(stid);
      notifyListeners();
    }
  }

  // Loading remove stid
  void loadingRemove(String stid) {
    if (loading.contains(stid)) {
      loading.remove(stid);
      notifyListeners();
    }
  }
}
