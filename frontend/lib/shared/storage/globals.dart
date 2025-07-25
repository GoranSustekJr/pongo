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

// Current album/playlist id
ValueNotifier<String> currentAlbumPlaylistId = ValueNotifier("");

// Is the current track showing
ValueNotifier<double> currentTrackHeight = ValueNotifier(0);

// Use sync time delay
ValueNotifier<bool> useSyncTimeDelay = ValueNotifier(false);

// Use synced lyrics
ValueNotifier<bool> useSyncedLyrics = ValueNotifier(false);

// Current blurhash
ValueNotifier<String> currentBlurhash = ValueNotifier(AppConstants().BLURHASH);

// Number of artists to display
ValueNotifier<int> numberOfSearchArtists = ValueNotifier(3);

// Number of albums to display
ValueNotifier<int> numberOfSearchAlbums = ValueNotifier(5);

// Number of tracks to display
ValueNotifier<int> numberOfSearchTracks = ValueNotifier(50);

// Number of playlists to display
ValueNotifier<int> numberOfSearchPlaylists = ValueNotifier(20);

// Queue allow shuffle
ValueNotifier<bool> queueAllowShuffle = ValueNotifier(true);

// Album/Playlist allow changing song on tap
ValueNotifier<bool> changeTrackOnTap = ValueNotifier(true);

// lyrics text align
ValueNotifier<TextAlign> currentLyricsTextAlignment =
    ValueNotifier(TextAlign.center);

// Next Screen on
ValueNotifier<bool> nextScreenOn = ValueNotifier(false);

// Search screen context
ValueNotifier<BuildContext?> searchScreenContext = ValueNotifier(null);

// Main context
ValueNotifier<BuildContext?> mainContext = ValueNotifier(null);

// Use caching audio sourece
ValueNotifier<bool> useCacheAudioSource = ValueNotifier(false);

// Enable lyris
ValueNotifier<bool> enableLyrics = ValueNotifier(true);

// Search focus node
ValueNotifier<FocusNode> searchFocusNode = ValueNotifier(FocusNode());

// Show Playlist add
ValueNotifier<bool> showPlaylistHandler = ValueNotifier(false);

// Show Playlist track to add data
ValueNotifier<Map?> playlistTrackToAddData = ValueNotifier(null);

// Playlist handler
ValueNotifier<PlaylistHandler?> playlistHandler = ValueNotifier(null);

// Notifications context
ValueNotifier<BuildContext?> notificationsContext = ValueNotifier(null);

// Search data manager
ValueNotifier<SearchDataManager?> searchDataManagr = ValueNotifier(null);

// Cache images
ValueNotifier<bool> cacheImages = ValueNotifier(false);

// Subscriptions
List<ProductDetails> subscriptionModels = [];

// In app purchase instance
InAppPurchase? inAppPurchaseInstance;

// Subsciption level
ValueNotifier<String> subscriptionLevel = ValueNotifier("");

// Premium
ValueNotifier<bool> premium = ValueNotifier(true);

// Use blur
ValueNotifier<bool> useBlur = ValueNotifier(true);

// Use detailed blurhash
ValueNotifier<bool> detailedBlurhash = ValueNotifier(true);

// Use Mix
ValueNotifier<bool> useMix = ValueNotifier(true);

// Shazaming
bool shazaming = false;

// Sleep alarm device volume
double sleepAlarmDevVolume = 0.5;

// Fullscreen Playing
ValueNotifier<bool> fullscreenPlaying = ValueNotifier(false);

// Dark mode
ValueNotifier<bool> darkMode = ValueNotifier(true);

// linear sleep-in
bool linearSleepin = true;

// linear wake-up
bool linearWakeup = true;

// Use dynamic blurhash
bool useDynamicBlurhash = false;

// Queue offset
double queueScrollOffset = 0;

// Use animations
bool animations = true;

// Use liquid glass
bool liquidGlassEnabled = false;
