import '../../exports.dart';

// Bottom Nav Bar Index
ValueNotifier<int> navigationBarIndex = ValueNotifier(0);

// Search Bar Is Searching?
ValueNotifier<bool> searchBarIsSearching = ValueNotifier(false);

// Is User Signed In?
ValueNotifier<bool> isUserSignedIn = ValueNotifier(false);

// Show bottom nav bar
ValueNotifier<bool> showBottomNavBar = ValueNotifier(true);

// Show search bar
ValueNotifier<bool> showSearchBar = ValueNotifier(true);

// Current track stid
ValueNotifier<String> currentStid = ValueNotifier("");
