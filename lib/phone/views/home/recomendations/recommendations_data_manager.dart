import 'package:pongo/exports.dart';
import 'package:pongo/shared/models/spotify/category.dart';

class RecommendationsDataManager with ChangeNotifier {
  final BuildContext context;
  RecommendationsDataManager(this.context) {
    init();
  }

  // Show body
  bool showBody = false;

  // Bool recomendations disabled
  bool historyEnabled = true;
  bool categoriesEnabled = true;

  // Categories
  List<SpCategory> categories = [];

  // History tracks
  List<Track> history = [];

  // Loading
  List<String> loading = [];

  // Suggestion header
  final TextStyle suggestionHeader = TextStyle(
    fontSize: kIsApple ? 24 : 19,
    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w700,
    color: Colors.white,
  );

  // Init the manager
  Future<void> init() async {
    // Check if user wants to get recommendations
    bool getHistory = await Storage().getEnableHistory();
    bool getCatgories = await Storage().getEnableCategories();

    historyEnabled = getHistory;
    categoriesEnabled = getCatgories;

    if (historyEnabled || categoriesEnabled) {
      final data = await Recommendations().get(context);

      // Set the categories
      categories =
          SpCategory.fromMapList(data["categories"]["categories"]["items"]);

      // Set the history
      history = Track.fromMapList(data["history"]["tracks"]);
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
