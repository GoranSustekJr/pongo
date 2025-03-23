import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('hr')
  ];

  /// Current language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Sleep
  ///
  /// In en, this message translates to:
  /// **'Sleep alarm'**
  String get sleep;

  /// Sleep & alarm clock
  ///
  /// In en, this message translates to:
  /// **'Sleep & alarm clock'**
  String get sleepandalarmclock;

  /// Shazam failed
  ///
  /// In en, this message translates to:
  /// **'Shazam failed to recognize the song'**
  String get shazamfailed;

  /// premiumisneededtodownloadatrack
  ///
  /// In en, this message translates to:
  /// **'Premium is needed to download a track'**
  String get premiumisneededtodownloadatrack;

  /// premiumisneededtosavethequeue
  ///
  /// In en, this message translates to:
  /// **'Premium is needed to save the queue'**
  String get premiumisneededtosavethequeue;

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okey;

  /// User interface
  ///
  /// In en, this message translates to:
  /// **'User interface'**
  String get userinterface;

  /// Use blur
  ///
  /// In en, this message translates to:
  /// **'Use blur'**
  String get useblur;

  /// Turn off if your device is getting hot or has lag
  ///
  /// In en, this message translates to:
  /// **'Turn off if your device is getting hot or has lag'**
  String get turnoffifyourdeviceisgettinghotorhaslag;

  /// pleaseleavethepageafterasuccessfullpurchase
  ///
  /// In en, this message translates to:
  /// **'Please leave the page after a successfull purchase'**
  String get pleaseleavethepageafterasuccessfullpurchase;

  /// Are You Sure?
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areyousure;

  /// Clear Queue?
  ///
  /// In en, this message translates to:
  /// **'Clear queue?'**
  String get clearqueue;

  /// Clear Queue?
  ///
  /// In en, this message translates to:
  /// **'In order to play the song, the queue needs to be cleared.'**
  String get clearqueuebody;

  /// sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signin;

  /// Sign in with
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get signinwith;

  /// By signing in you
  ///
  /// In en, this message translates to:
  /// **'By signing in you accept our terms of service and privacy policies.'**
  String get bysigninginyou;

  /// Sign in with
  ///
  /// In en, this message translates to:
  /// **'With Pongo life sounds beter'**
  String get klemen;

  /// or
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// sleepalarmisenabled
  ///
  /// In en, this message translates to:
  /// **'Sleep alarm is enabled'**
  String get sleepalarmisenabled;

  /// unabletohaltthemusicplayer
  ///
  /// In en, this message translates to:
  /// **'Unable to halt the music player'**
  String get unabletohaltthemusicplayer;

  /// unabletohaltthemusicplayerbecausesleepalarmiscurrentlyon
  ///
  /// In en, this message translates to:
  /// **'Unable to halt the music player because sleep alarm is currently on'**
  String get unabletohaltthemusicplayerbecausesleepalarmiscurrentlyon;

  /// profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// accountdisabled
  ///
  /// In en, this message translates to:
  /// **'Account disabled'**
  String get accountdisabled;

  /// pleasecontactinordertoenableyouraccountandusetheapp
  ///
  /// In en, this message translates to:
  /// **'Please conntact pongo.group@gmail.com in order to enable your account and use the app'**
  String get pleasecontactinordertoenableyouraccountandusetheapp;

  /// hidden
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// allofyourdataishidden
  ///
  /// In en, this message translates to:
  /// **'All of your data is hidden'**
  String get allofyourdataishidden;

  /// name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// startpage
  ///
  /// In en, this message translates to:
  /// **'Start page'**
  String get startpage;

  /// showhistory
  ///
  /// In en, this message translates to:
  /// **'Show history'**
  String get showhistory;

  /// buypremium
  ///
  /// In en, this message translates to:
  /// **'Buy Pongo premium'**
  String get buypremium;

  /// showhistoryonstartpage
  ///
  /// In en, this message translates to:
  /// **'Show history on start page'**
  String get showhistoryonstartpage;

  /// showexplore
  ///
  /// In en, this message translates to:
  /// **'Show explore'**
  String get showexplore;

  /// showexploreonstartpage
  ///
  /// In en, this message translates to:
  /// **'Show explore on start page'**
  String get showexploreonstartpage;

  /// downloadtracksnow
  ///
  /// In en, this message translates to:
  /// **'Download tracks now!'**
  String get downloadtracksnow;

  /// addtrackstoyoutplaylist
  ///
  /// In en, this message translates to:
  /// **'Add tracks to your playlist!'**
  String get addtrackstoyoutplaylist;

  /// createnewplaylistnow
  ///
  /// In en, this message translates to:
  /// **'Create a new playlist now!'**
  String get createnewplaylistnow;

  /// findyourfavouritesongsnow
  ///
  /// In en, this message translates to:
  /// **'Find your favourite songs now!'**
  String get findyourfavouritesongsnow;

  /// email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// premium
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// subscribed
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get subscribed;

  /// sign out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signout;

  /// settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// yourprofile
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourprofile;

  /// library
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// playlist
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// favouritesongs
  ///
  /// In en, this message translates to:
  /// **'Favourite Songs'**
  String get favouritesongs;

  /// onlinefavouritesongs
  ///
  /// In en, this message translates to:
  /// **'Online Favourite Songs'**
  String get onlinefavouritesongs;

  /// playlists
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// onlineplaylists
  ///
  /// In en, this message translates to:
  /// **'Online Playlists'**
  String get onlineplaylists;

  /// songs
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// offlinesongs
  ///
  /// In en, this message translates to:
  /// **'Offline Songs'**
  String get offlinesongs;

  /// offlineplaylists
  ///
  /// In en, this message translates to:
  /// **'Offline Playlists'**
  String get offlineplaylists;

  /// offlineplaylist
  ///
  /// In en, this message translates to:
  /// **'Offline Playlist'**
  String get offlineplaylist;

  /// newplaylist
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newplaylist;

  /// create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// addtoplaylist
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addtoplaylist;

  /// like
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// unlike
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// artist
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// artists
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// plain
  ///
  /// In en, this message translates to:
  /// **'plain'**
  String get plain;

  /// sync
  ///
  /// In en, this message translates to:
  /// **'sync'**
  String get sync;

  /// nosynclyrics
  ///
  /// In en, this message translates to:
  /// **'No synced lyrics'**
  String get nosynclyrics;

  /// noplainlyrics
  ///
  /// In en, this message translates to:
  /// **'No plain lyrics'**
  String get noplainlyrics;

  /// wanttohelpoutlyrics
  ///
  /// In en, this message translates to:
  /// **'Want to help out? Add lyrics to lrclib.net!'**
  String get wanttohelpoutlyrics;

  /// album
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// albums
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// tracks
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// removetrackfromplaylist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this track from the playlist?'**
  String get removetrackfromplaylist;

  /// removeselectedfromplaylist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove selected from the playlist?'**
  String get removeselectedfromplaylist;

  /// removefromplaylist
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removefromplaylist;

  /// continuee
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuee;

  /// removeplaylist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this playlist?'**
  String get removeplaylist;

  /// haltmusicplayer
  ///
  /// In en, this message translates to:
  /// **'Halt the music player?'**
  String get haltmusicplayer;

  /// haltmusicplayerbody
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to halt the music player?'**
  String get haltmusicplayerbody;

  /// halt
  ///
  /// In en, this message translates to:
  /// **'Halt'**
  String get halt;

  /// changetitle
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changetitle;

  /// taptochange
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get taptochange;

  /// change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// changeplaylisttile
  ///
  /// In en, this message translates to:
  /// **'Change playlist title'**
  String get changeplaylisttile;

  /// changeplaylisttilebody
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the playlist title?'**
  String get changeplaylisttilebody;

  /// pleaseallowaccesstophotogalery
  ///
  /// In en, this message translates to:
  /// **'Please allow Pongo acces to your photo gallery'**
  String get pleaseallowaccesstophotogalery;

  /// editplaylist
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get editplaylist;

  /// editplaylistbody
  ///
  /// In en, this message translates to:
  /// **'The playlist must not be playing while editing. In order to edit it, halt the playlist'**
  String get editplaylistbody;

  /// selectedtracks
  ///
  /// In en, this message translates to:
  /// **'Selected tracks'**
  String get selectedtracks;

  /// delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// removetracksfromplaylist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove these tracks from the playlist?'**
  String get removetracksfromplaylist;

  /// preferences
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// yourpreferences
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get yourpreferences;

  /// Country code
  ///
  /// In en, this message translates to:
  /// **'Country code: '**
  String get countrycode;

  /// Search preferences
  ///
  /// In en, this message translates to:
  /// **'Search preferences'**
  String get searchpreferences;

  /// Country code
  ///
  /// In en, this message translates to:
  /// **'Search market'**
  String get searchmarket;

  /// selectmarket
  ///
  /// In en, this message translates to:
  /// **'Select market'**
  String get selectmarket;

  /// selectmarketbody
  ///
  /// In en, this message translates to:
  /// **'Search resulsts and suggestions depend on the selected market'**
  String get selectmarketbody;

  /// foryou
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get foryou;

  /// releasedAlbums
  ///
  /// In en, this message translates to:
  /// **'Released albums'**
  String get releasedAlbums;

  /// singles
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get singles;

  /// compilations
  ///
  /// In en, this message translates to:
  /// **'Compilations'**
  String get compilations;

  /// appearson
  ///
  /// In en, this message translates to:
  /// **'Appears on'**
  String get appearson;

  /// noalbums
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get noalbums;

  /// playlistalreadycontainsthistrack
  ///
  /// In en, this message translates to:
  /// **'Playlist already contains this track'**
  String get playlistalreadycontainsthistrack;

  /// notracks
  ///
  /// In en, this message translates to:
  /// **'No tracks'**
  String get notracks;

  /// toptentracks
  ///
  /// In en, this message translates to:
  /// **'Top 10 Tracks'**
  String get toptentracks;

  /// doublecliktoadjustvolume
  ///
  /// In en, this message translates to:
  /// **'Double click to adjust volume'**
  String get doublecliktoadjustvolume;

  /// newalbums
  ///
  /// In en, this message translates to:
  /// **'New albums'**
  String get newalbums;

  /// lyrics
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// trackdownloaded
  ///
  /// In en, this message translates to:
  /// **'Track downloaded'**
  String get trackdownloaded;

  /// createnewplaylist
  ///
  /// In en, this message translates to:
  /// **'Create new playlist'**
  String get createnewplaylist;

  /// alreadyinplaylist
  ///
  /// In en, this message translates to:
  /// **'Already in playlist'**
  String get alreadyinplaylist;

  /// addsongtoplaylist
  ///
  /// In en, this message translates to:
  /// **'Add song to playlist'**
  String get addsongtoplaylist;

  /// newplaylistlocal
  ///
  /// In en, this message translates to:
  /// **'New local playlist'**
  String get newplaylistlocal;

  /// playlistdownloaded
  ///
  /// In en, this message translates to:
  /// **'Playlist downloaded'**
  String get playlistdownloaded;

  /// clearallhistory
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get clearallhistory;

  /// clearallhistorybody
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all search history?'**
  String get clearallhistorybody;

  /// topten
  ///
  /// In en, this message translates to:
  /// **'Top 10'**
  String get topten;

  /// Singles and compilations
  ///
  /// In en, this message translates to:
  /// **'Singles and compilations'**
  String get singlesandcompilations;

  /// relatedartists
  ///
  /// In en, this message translates to:
  /// **'Related artists'**
  String get relatedartists;

  /// data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// saveyourdata
  ///
  /// In en, this message translates to:
  /// **'Save your data'**
  String get saveyourdata;

  /// clearaudioplayercache
  ///
  /// In en, this message translates to:
  /// **'Clear audio player cache'**
  String get clearaudioplayercache;

  /// clearyouraudioplayercache
  ///
  /// In en, this message translates to:
  /// **'Clear your audio player cache'**
  String get clearyouraudioplayercache;

  /// clearimagecache
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get clearimagecache;

  /// clearyourassetimagecache
  ///
  /// In en, this message translates to:
  /// **'Clear your asset image cache'**
  String get clearyourassetimagecache;

  /// clearallcache
  ///
  /// In en, this message translates to:
  /// **'Clear all cache'**
  String get clearallcache;

  /// clearallappcache
  ///
  /// In en, this message translates to:
  /// **'Clear all app cache'**
  String get clearallappcache;

  /// cache
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// howmanyartistsshownwhensearching
  ///
  /// In en, this message translates to:
  /// **'How many artists shown when searching'**
  String get howmanyartistsshownwhensearching;

  /// howmanyalbumsshownwhensearching
  ///
  /// In en, this message translates to:
  /// **'How many albums shown when searching'**
  String get howmanyalbumsshownwhensearching;

  /// howmanytracksshownwhensearching
  ///
  /// In en, this message translates to:
  /// **'How many tracks shown when searching'**
  String get howmanytracksshownwhensearching;

  /// howmanyplaylistsshownwhensearching
  ///
  /// In en, this message translates to:
  /// **'How many playlists shown when searching'**
  String get howmanyplaylistsshownwhensearching;

  /// synctimedelay
  ///
  /// In en, this message translates to:
  /// **'Sync time delay'**
  String get synctimedelay;

  /// usesynctimedelay
  ///
  /// In en, this message translates to:
  /// **'Use sync time delay'**
  String get usesynctimedelay;

  /// prefersyncedlyrics
  ///
  /// In en, this message translates to:
  /// **'Prefer synced lyrics'**
  String get prefersyncedlyrics;

  /// preferusageofsyncedlyrics
  ///
  /// In en, this message translates to:
  /// **'Prefer usage of synced lyrics'**
  String get preferusageofsyncedlyrics;

  /// recommendations
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// showrecommendedforyou
  ///
  /// In en, this message translates to:
  /// **'Show recommended for you'**
  String get showrecommendedforyou;

  /// showrecommendedforyoubody
  ///
  /// In en, this message translates to:
  /// **'Show recommendations from your five most recent tracks'**
  String get showrecommendedforyoubody;

  /// showrecommendedbypongo
  ///
  /// In en, this message translates to:
  /// **'Show recommended by Pongo'**
  String get showrecommendedbypongo;

  /// showrecommendedbypongobody
  ///
  /// In en, this message translates to:
  /// **'Show random recommendations by Pongo'**
  String get showrecommendedbypongobody;

  /// recommendationsdisabled
  ///
  /// In en, this message translates to:
  /// **'Recommendations disabled. They can be enabled in \'Settings > Preferences > Recommmendations\'. Then restart the app.'**
  String get recommendationsdisabled;

  /// firsttoqueue
  ///
  /// In en, this message translates to:
  /// **'First to queue'**
  String get firsttoqueue;

  /// lasttoqueue
  ///
  /// In en, this message translates to:
  /// **'Last to queue'**
  String get lasttoqueue;

  /// warning
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// shufflemodeison
  ///
  /// In en, this message translates to:
  /// **'Shuffle mode is on!'**
  String get shufflemodeison;

  /// leftalignment
  ///
  /// In en, this message translates to:
  /// **'Left alignment'**
  String get leftalignment;

  /// centeralignment
  ///
  /// In en, this message translates to:
  /// **'Center alignment'**
  String get centeralignment;

  /// rightalignment
  ///
  /// In en, this message translates to:
  /// **'Right alignment'**
  String get rightalignment;

  /// justify
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get justify;

  /// lefttextalign
  ///
  /// In en, this message translates to:
  /// **'Left text align'**
  String get lefttextalign;

  /// centertextalign
  ///
  /// In en, this message translates to:
  /// **'Center text align'**
  String get centertextalign;

  /// righttextalign
  ///
  /// In en, this message translates to:
  /// **'Right text align'**
  String get righttextalign;

  /// justifytextalign
  ///
  /// In en, this message translates to:
  /// **'Justify text align'**
  String get justifytextalign;

  /// alignment
  ///
  /// In en, this message translates to:
  /// **'alignment'**
  String get alignment;

  /// lyircstextalignment
  ///
  /// In en, this message translates to:
  /// **'Lyrics text alignment'**
  String get lyircstextalignment;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// saveasplaylist
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get saveasplaylist;

  /// successful
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// trackremovedfromfavourites
  ///
  /// In en, this message translates to:
  /// **'Track removed from favourites'**
  String get trackremovedfromfavourites;

  /// trackisnowafavourite
  ///
  /// In en, this message translates to:
  /// **'Track is now a favourite'**
  String get trackisnowafavourite;

  /// removefromfavourites
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removefromfavourites;

  /// removefromfavouritesbody
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove selected tracks from favourites?'**
  String get removefromfavouritesbody;

  /// lyricsdisabled
  ///
  /// In en, this message translates to:
  /// **'Lyrics disabled'**
  String get lyricsdisabled;

  /// enablelyrics
  ///
  /// In en, this message translates to:
  /// **'Enable lyrics'**
  String get enablelyrics;

  /// enableusageoflyrics
  ///
  /// In en, this message translates to:
  /// **'Enable usage of lyrics'**
  String get enableusageoflyrics;

  /// audioplayer
  ///
  /// In en, this message translates to:
  /// **'Audio player'**
  String get audioplayer;

  /// audioplayercaching
  ///
  /// In en, this message translates to:
  /// **'Audio player caching'**
  String get audioplayercaching;

  /// letaudioplayercachethesongs
  ///
  /// In en, this message translates to:
  /// **'Let audio player cache the songs'**
  String get letaudioplayercachethesongs;

  /// playlistname
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistname;

  /// successfullysavedsynctimedelay
  ///
  /// In en, this message translates to:
  /// **'Successfully saved sync time delay for this tracks lyrics'**
  String get successfullysavedsynctimedelay;

  /// playlistnamealreadyexists
  ///
  /// In en, this message translates to:
  /// **'Playlist with the same name already exists'**
  String get playlistnamealreadyexists;

  /// pleaseenablepongoaccesstophotos
  ///
  /// In en, this message translates to:
  /// **'Please enable Pongo access to photos'**
  String get pleaseenablepongoaccesstophotos;

  /// onlineplaylist
  ///
  /// In en, this message translates to:
  /// **'Online playlist'**
  String get onlineplaylist;

  /// donotterminatetheapp
  ///
  /// In en, this message translates to:
  /// **'Do NOT terminate the app'**
  String get donotterminatetheapp;

  /// cannotstartalarm
  ///
  /// In en, this message translates to:
  /// **'Can\'t start the alarm'**
  String get cannotstartalarm;

  /// thequeuemustnotbeemptyinordertostartthealarm
  ///
  /// In en, this message translates to:
  /// **'The queue must not be empty in order to start the alarm'**
  String get thequeuemustnotbeemptyinordertostartthealarm;

  /// maximumvolumeofthealarm
  ///
  /// In en, this message translates to:
  /// **'Maximum volume of the alarm'**
  String get maximumvolumeofthealarm;

  /// createnewsleepalarm
  ///
  /// In en, this message translates to:
  /// **'Create new sleep alarm'**
  String get createnewsleepalarm;

  /// off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// sleepin
  ///
  /// In en, this message translates to:
  /// **'Sleep in'**
  String get sleepin;

  /// alarm
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// cannotcreateasleepalarmwithoutthe
  ///
  /// In en, this message translates to:
  /// **'Cannot create a sleep alarm without the \'sleep in\' or \'alarm\''**
  String get cannotcreateasleepalarmwithoutthe;

  /// pongowillgraduallylowerthevolumefor
  ///
  /// In en, this message translates to:
  /// **'Pongo will gradually lower the volume for'**
  String get pongowillgraduallylowerthevolumefor;

  /// pongowillgraduallyincreasethevolume
  ///
  /// In en, this message translates to:
  /// **'Pongo will gradually increase the valume'**
  String get pongowillgraduallyincreasethevolume;

  /// beforeyouneedtowakeupat
  ///
  /// In en, this message translates to:
  /// **'before you need to wake up at'**
  String get beforeyouneedtowakeupat;

  /// about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// aboutpongo
  ///
  /// In en, this message translates to:
  /// **'About Pongo'**
  String get aboutpongo;

  /// contactusviamail
  ///
  /// In en, this message translates to:
  /// **'Contact us via mail'**
  String get contactusviamail;

  /// termsandconditions
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsandconditions;

  /// ourtermsandconditions
  ///
  /// In en, this message translates to:
  /// **'Our Terms & Conditions'**
  String get ourtermsandconditions;

  /// privacypolicy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacypolicy;

  /// ourprivacypolicy
  ///
  /// In en, this message translates to:
  /// **'Our Privacy Policy'**
  String get ourprivacypolicy;

  /// cropimage
  ///
  /// In en, this message translates to:
  /// **'Crop image'**
  String get cropimage;

  /// plustracks
  ///
  /// In en, this message translates to:
  /// **'songs'**
  String get plustracks;

  /// changename
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get changename;

  /// hide
  ///
  /// In en, this message translates to:
  /// **'hide'**
  String get hide;

  /// show
  ///
  /// In en, this message translates to:
  /// **'show'**
  String get show;

  /// notification
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// trackalreadydownloaded
  ///
  /// In en, this message translates to:
  /// **'Track is already downloaded'**
  String get trackalreadydownloaded;

  /// successfullydownloadedthetrack
  ///
  /// In en, this message translates to:
  /// **'Successfully downloaded the track'**
  String get successfullydownloadedthetrack;

  /// repeatoff
  ///
  /// In en, this message translates to:
  /// **'Repeat is off'**
  String get repeatoff;

  /// repeatthissong
  ///
  /// In en, this message translates to:
  /// **'Repet one song'**
  String get repeatthissong;

  /// repeatthequeue
  ///
  /// In en, this message translates to:
  /// **'Repeat the queue'**
  String get repeatthequeue;

  /// removefromdownloaded
  ///
  /// In en, this message translates to:
  /// **'Remove from downloaded'**
  String get removefromdownloaded;

  /// removefromdownloadedbody
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove selected tracks from downloaded?'**
  String get removefromdownloadedbody;

  /// lastlistenedto
  ///
  /// In en, this message translates to:
  /// **'Last listened to'**
  String get lastlistenedto;

  /// explore
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// images
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// imagecaching
  ///
  /// In en, this message translates to:
  /// **'Image caching'**
  String get imagecaching;

  /// cacheimagestoreducenetworkactivity
  ///
  /// In en, this message translates to:
  /// **'Cache images to reduce network activity'**
  String get cacheimagestoreducenetworkactivity;

  /// deleteyouraccount
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteyouraccount;

  /// bydeletingyouraccountyouwilldeleteallyourprivilegesifpayingpremium
  ///
  /// In en, this message translates to:
  /// **'By deleting your account, you will delete all your privileges if paying premium'**
  String get bydeletingyouraccountyouwilldeleteallyourprivilegesifpayingpremium;

  /// deleteaccount
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteaccount;

  /// areyousurezouwanttodeleteyouraccount
  ///
  /// In en, this message translates to:
  /// **'Are you sure that you want to delete your account?'**
  String get areyousurezouwanttodeleteyouraccount;

  /// skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// downloadsucceeded
  ///
  /// In en, this message translates to:
  /// **'Download succedeed'**
  String get downloadsucceeded;

  /// downloadfailed
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadfailed;

  /// downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// downloadhasstarted
  ///
  /// In en, this message translates to:
  /// **'Download has started. DO NOT CLOSE THE APP!'**
  String get downloadhasstarted;

  /// firstadded
  ///
  /// In en, this message translates to:
  /// **'First added'**
  String get firstadded;

  /// lastadded
  ///
  /// In en, this message translates to:
  /// **'Last added'**
  String get lastadded;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'hr': return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
