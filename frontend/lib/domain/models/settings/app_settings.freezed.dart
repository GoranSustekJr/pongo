// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 String get locale; String get market; bool get useSyncTimeDelay; bool get useSyncedLyrics; int get searchArtistCount; int get searchAlbumCount; int get searchTrackCount; int get searchPlaylistCount; TextAlign get lyricsTextAlign; bool get useCacheAudioSource; bool get enableLyrics; bool get enableHistory; bool get enableCategories; int get categoryCount; bool get cacheImages; LocalsSort get localsSort; bool get useBlur; bool get useMix; bool get useDetailedBlurhash; double get sleepAlarmDeviceVolume; bool get darkMode; bool get linearSleepIn; bool get linearWakeUp; bool get useDynamicBlurhash; bool get useAnimations; bool get useLiquidGlass;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.market, _this.market) || other.market == _this.market)&&(identical(other.useSyncTimeDelay, _this.useSyncTimeDelay) || other.useSyncTimeDelay == _this.useSyncTimeDelay)&&(identical(other.useSyncedLyrics, _this.useSyncedLyrics) || other.useSyncedLyrics == _this.useSyncedLyrics)&&(identical(other.searchArtistCount, _this.searchArtistCount) || other.searchArtistCount == _this.searchArtistCount)&&(identical(other.searchAlbumCount, _this.searchAlbumCount) || other.searchAlbumCount == _this.searchAlbumCount)&&(identical(other.searchTrackCount, _this.searchTrackCount) || other.searchTrackCount == _this.searchTrackCount)&&(identical(other.searchPlaylistCount, _this.searchPlaylistCount) || other.searchPlaylistCount == _this.searchPlaylistCount)&&(identical(other.lyricsTextAlign, _this.lyricsTextAlign) || other.lyricsTextAlign == _this.lyricsTextAlign)&&(identical(other.useCacheAudioSource, _this.useCacheAudioSource) || other.useCacheAudioSource == _this.useCacheAudioSource)&&(identical(other.enableLyrics, _this.enableLyrics) || other.enableLyrics == _this.enableLyrics)&&(identical(other.enableHistory, _this.enableHistory) || other.enableHistory == _this.enableHistory)&&(identical(other.enableCategories, _this.enableCategories) || other.enableCategories == _this.enableCategories)&&(identical(other.categoryCount, _this.categoryCount) || other.categoryCount == _this.categoryCount)&&(identical(other.cacheImages, _this.cacheImages) || other.cacheImages == _this.cacheImages)&&(identical(other.localsSort, _this.localsSort) || other.localsSort == _this.localsSort)&&(identical(other.useBlur, _this.useBlur) || other.useBlur == _this.useBlur)&&(identical(other.useMix, _this.useMix) || other.useMix == _this.useMix)&&(identical(other.useDetailedBlurhash, _this.useDetailedBlurhash) || other.useDetailedBlurhash == _this.useDetailedBlurhash)&&(identical(other.sleepAlarmDeviceVolume, _this.sleepAlarmDeviceVolume) || other.sleepAlarmDeviceVolume == _this.sleepAlarmDeviceVolume)&&(identical(other.darkMode, _this.darkMode) || other.darkMode == _this.darkMode)&&(identical(other.linearSleepIn, _this.linearSleepIn) || other.linearSleepIn == _this.linearSleepIn)&&(identical(other.linearWakeUp, _this.linearWakeUp) || other.linearWakeUp == _this.linearWakeUp)&&(identical(other.useDynamicBlurhash, _this.useDynamicBlurhash) || other.useDynamicBlurhash == _this.useDynamicBlurhash)&&(identical(other.useAnimations, _this.useAnimations) || other.useAnimations == _this.useAnimations)&&(identical(other.useLiquidGlass, _this.useLiquidGlass) || other.useLiquidGlass == _this.useLiquidGlass));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hashAll([runtimeType,_this.locale,_this.market,_this.useSyncTimeDelay,_this.useSyncedLyrics,_this.searchArtistCount,_this.searchAlbumCount,_this.searchTrackCount,_this.searchPlaylistCount,_this.lyricsTextAlign,_this.useCacheAudioSource,_this.enableLyrics,_this.enableHistory,_this.enableCategories,_this.categoryCount,_this.cacheImages,_this.localsSort,_this.useBlur,_this.useMix,_this.useDetailedBlurhash,_this.sleepAlarmDeviceVolume,_this.darkMode,_this.linearSleepIn,_this.linearWakeUp,_this.useDynamicBlurhash,_this.useAnimations,_this.useLiquidGlass]);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(locale: ${_this.locale}, market: ${_this.market}, useSyncTimeDelay: ${_this.useSyncTimeDelay}, useSyncedLyrics: ${_this.useSyncedLyrics}, searchArtistCount: ${_this.searchArtistCount}, searchAlbumCount: ${_this.searchAlbumCount}, searchTrackCount: ${_this.searchTrackCount}, searchPlaylistCount: ${_this.searchPlaylistCount}, lyricsTextAlign: ${_this.lyricsTextAlign}, useCacheAudioSource: ${_this.useCacheAudioSource}, enableLyrics: ${_this.enableLyrics}, enableHistory: ${_this.enableHistory}, enableCategories: ${_this.enableCategories}, categoryCount: ${_this.categoryCount}, cacheImages: ${_this.cacheImages}, localsSort: ${_this.localsSort}, useBlur: ${_this.useBlur}, useMix: ${_this.useMix}, useDetailedBlurhash: ${_this.useDetailedBlurhash}, sleepAlarmDeviceVolume: ${_this.sleepAlarmDeviceVolume}, darkMode: ${_this.darkMode}, linearSleepIn: ${_this.linearSleepIn}, linearWakeUp: ${_this.linearWakeUp}, useDynamicBlurhash: ${_this.useDynamicBlurhash}, useAnimations: ${_this.useAnimations}, useLiquidGlass: ${_this.useLiquidGlass})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String locale, String market, bool useSyncTimeDelay, bool useSyncedLyrics, int searchArtistCount, int searchAlbumCount, int searchTrackCount, int searchPlaylistCount, TextAlign lyricsTextAlign, bool useCacheAudioSource, bool enableLyrics, bool enableHistory, bool enableCategories, int categoryCount, bool cacheImages, LocalsSort localsSort, bool useBlur, bool useMix, bool useDetailedBlurhash, double sleepAlarmDeviceVolume, bool darkMode, bool linearSleepIn, bool linearWakeUp, bool useDynamicBlurhash, bool useAnimations, bool useLiquidGlass
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = null,Object? market = null,Object? useSyncTimeDelay = null,Object? useSyncedLyrics = null,Object? searchArtistCount = null,Object? searchAlbumCount = null,Object? searchTrackCount = null,Object? searchPlaylistCount = null,Object? lyricsTextAlign = null,Object? useCacheAudioSource = null,Object? enableLyrics = null,Object? enableHistory = null,Object? enableCategories = null,Object? categoryCount = null,Object? cacheImages = null,Object? localsSort = null,Object? useBlur = null,Object? useMix = null,Object? useDetailedBlurhash = null,Object? sleepAlarmDeviceVolume = null,Object? darkMode = null,Object? linearSleepIn = null,Object? linearWakeUp = null,Object? useDynamicBlurhash = null,Object? useAnimations = null,Object? useLiquidGlass = null,}) {
  return _then(AppSettings(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,useSyncTimeDelay: null == useSyncTimeDelay ? _self.useSyncTimeDelay : useSyncTimeDelay // ignore: cast_nullable_to_non_nullable
as bool,useSyncedLyrics: null == useSyncedLyrics ? _self.useSyncedLyrics : useSyncedLyrics // ignore: cast_nullable_to_non_nullable
as bool,searchArtistCount: null == searchArtistCount ? _self.searchArtistCount : searchArtistCount // ignore: cast_nullable_to_non_nullable
as int,searchAlbumCount: null == searchAlbumCount ? _self.searchAlbumCount : searchAlbumCount // ignore: cast_nullable_to_non_nullable
as int,searchTrackCount: null == searchTrackCount ? _self.searchTrackCount : searchTrackCount // ignore: cast_nullable_to_non_nullable
as int,searchPlaylistCount: null == searchPlaylistCount ? _self.searchPlaylistCount : searchPlaylistCount // ignore: cast_nullable_to_non_nullable
as int,lyricsTextAlign: null == lyricsTextAlign ? _self.lyricsTextAlign : lyricsTextAlign // ignore: cast_nullable_to_non_nullable
as TextAlign,useCacheAudioSource: null == useCacheAudioSource ? _self.useCacheAudioSource : useCacheAudioSource // ignore: cast_nullable_to_non_nullable
as bool,enableLyrics: null == enableLyrics ? _self.enableLyrics : enableLyrics // ignore: cast_nullable_to_non_nullable
as bool,enableHistory: null == enableHistory ? _self.enableHistory : enableHistory // ignore: cast_nullable_to_non_nullable
as bool,enableCategories: null == enableCategories ? _self.enableCategories : enableCategories // ignore: cast_nullable_to_non_nullable
as bool,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,cacheImages: null == cacheImages ? _self.cacheImages : cacheImages // ignore: cast_nullable_to_non_nullable
as bool,localsSort: null == localsSort ? _self.localsSort : localsSort // ignore: cast_nullable_to_non_nullable
as LocalsSort,useBlur: null == useBlur ? _self.useBlur : useBlur // ignore: cast_nullable_to_non_nullable
as bool,useMix: null == useMix ? _self.useMix : useMix // ignore: cast_nullable_to_non_nullable
as bool,useDetailedBlurhash: null == useDetailedBlurhash ? _self.useDetailedBlurhash : useDetailedBlurhash // ignore: cast_nullable_to_non_nullable
as bool,sleepAlarmDeviceVolume: null == sleepAlarmDeviceVolume ? _self.sleepAlarmDeviceVolume : sleepAlarmDeviceVolume // ignore: cast_nullable_to_non_nullable
as double,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,linearSleepIn: null == linearSleepIn ? _self.linearSleepIn : linearSleepIn // ignore: cast_nullable_to_non_nullable
as bool,linearWakeUp: null == linearWakeUp ? _self.linearWakeUp : linearWakeUp // ignore: cast_nullable_to_non_nullable
as bool,useDynamicBlurhash: null == useDynamicBlurhash ? _self.useDynamicBlurhash : useDynamicBlurhash // ignore: cast_nullable_to_non_nullable
as bool,useAnimations: null == useAnimations ? _self.useAnimations : useAnimations // ignore: cast_nullable_to_non_nullable
as bool,useLiquidGlass: null == useLiquidGlass ? _self.useLiquidGlass : useLiquidGlass // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String locale,  String market,  bool useSyncTimeDelay,  bool useSyncedLyrics,  int searchArtistCount,  int searchAlbumCount,  int searchTrackCount,  int searchPlaylistCount,  TextAlign lyricsTextAlign,  bool useCacheAudioSource,  bool enableLyrics,  bool enableHistory,  bool enableCategories,  int categoryCount,  bool cacheImages,  LocalsSort localsSort,  bool useBlur,  bool useMix,  bool useDetailedBlurhash,  double sleepAlarmDeviceVolume,  bool darkMode,  bool linearSleepIn,  bool linearWakeUp,  bool useDynamicBlurhash,  bool useAnimations,  bool useLiquidGlass)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.locale,_that.market,_that.useSyncTimeDelay,_that.useSyncedLyrics,_that.searchArtistCount,_that.searchAlbumCount,_that.searchTrackCount,_that.searchPlaylistCount,_that.lyricsTextAlign,_that.useCacheAudioSource,_that.enableLyrics,_that.enableHistory,_that.enableCategories,_that.categoryCount,_that.cacheImages,_that.localsSort,_that.useBlur,_that.useMix,_that.useDetailedBlurhash,_that.sleepAlarmDeviceVolume,_that.darkMode,_that.linearSleepIn,_that.linearWakeUp,_that.useDynamicBlurhash,_that.useAnimations,_that.useLiquidGlass);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String locale,  String market,  bool useSyncTimeDelay,  bool useSyncedLyrics,  int searchArtistCount,  int searchAlbumCount,  int searchTrackCount,  int searchPlaylistCount,  TextAlign lyricsTextAlign,  bool useCacheAudioSource,  bool enableLyrics,  bool enableHistory,  bool enableCategories,  int categoryCount,  bool cacheImages,  LocalsSort localsSort,  bool useBlur,  bool useMix,  bool useDetailedBlurhash,  double sleepAlarmDeviceVolume,  bool darkMode,  bool linearSleepIn,  bool linearWakeUp,  bool useDynamicBlurhash,  bool useAnimations,  bool useLiquidGlass)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.locale,_that.market,_that.useSyncTimeDelay,_that.useSyncedLyrics,_that.searchArtistCount,_that.searchAlbumCount,_that.searchTrackCount,_that.searchPlaylistCount,_that.lyricsTextAlign,_that.useCacheAudioSource,_that.enableLyrics,_that.enableHistory,_that.enableCategories,_that.categoryCount,_that.cacheImages,_that.localsSort,_that.useBlur,_that.useMix,_that.useDetailedBlurhash,_that.sleepAlarmDeviceVolume,_that.darkMode,_that.linearSleepIn,_that.linearWakeUp,_that.useDynamicBlurhash,_that.useAnimations,_that.useLiquidGlass);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String locale,  String market,  bool useSyncTimeDelay,  bool useSyncedLyrics,  int searchArtistCount,  int searchAlbumCount,  int searchTrackCount,  int searchPlaylistCount,  TextAlign lyricsTextAlign,  bool useCacheAudioSource,  bool enableLyrics,  bool enableHistory,  bool enableCategories,  int categoryCount,  bool cacheImages,  LocalsSort localsSort,  bool useBlur,  bool useMix,  bool useDetailedBlurhash,  double sleepAlarmDeviceVolume,  bool darkMode,  bool linearSleepIn,  bool linearWakeUp,  bool useDynamicBlurhash,  bool useAnimations,  bool useLiquidGlass)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.locale,_that.market,_that.useSyncTimeDelay,_that.useSyncedLyrics,_that.searchArtistCount,_that.searchAlbumCount,_that.searchTrackCount,_that.searchPlaylistCount,_that.lyricsTextAlign,_that.useCacheAudioSource,_that.enableLyrics,_that.enableHistory,_that.enableCategories,_that.categoryCount,_that.cacheImages,_that.localsSort,_that.useBlur,_that.useMix,_that.useDetailedBlurhash,_that.sleepAlarmDeviceVolume,_that.darkMode,_that.linearSleepIn,_that.linearWakeUp,_that.useDynamicBlurhash,_that.useAnimations,_that.useLiquidGlass);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.locale = 'en', this.market = 'US', this.useSyncTimeDelay = false, this.useSyncedLyrics = true, this.searchArtistCount = 1, this.searchAlbumCount = 1, this.searchTrackCount = 50, this.searchPlaylistCount = 20, this.lyricsTextAlign = TextAlign.left, this.useCacheAudioSource = false, this.enableLyrics = true, this.enableHistory = true, this.enableCategories = true, this.categoryCount = 50, this.cacheImages = false, this.localsSort = LocalsSort.titleAscending, this.useBlur = true, this.useMix = true, this.useDetailedBlurhash = true, this.sleepAlarmDeviceVolume = 0, this.darkMode = true, this.linearSleepIn = true, this.linearWakeUp = true, this.useDynamicBlurhash = false, this.useAnimations = true, this.useLiquidGlass = true});
  

@override@JsonKey() final  String locale;
@override@JsonKey() final  String market;
@override@JsonKey() final  bool useSyncTimeDelay;
@override@JsonKey() final  bool useSyncedLyrics;
@override@JsonKey() final  int searchArtistCount;
@override@JsonKey() final  int searchAlbumCount;
@override@JsonKey() final  int searchTrackCount;
@override@JsonKey() final  int searchPlaylistCount;
@override@JsonKey() final  TextAlign lyricsTextAlign;
@override@JsonKey() final  bool useCacheAudioSource;
@override@JsonKey() final  bool enableLyrics;
@override@JsonKey() final  bool enableHistory;
@override@JsonKey() final  bool enableCategories;
@override@JsonKey() final  int categoryCount;
@override@JsonKey() final  bool cacheImages;
@override@JsonKey() final  LocalsSort localsSort;
@override@JsonKey() final  bool useBlur;
@override@JsonKey() final  bool useMix;
@override@JsonKey() final  bool useDetailedBlurhash;
@override@JsonKey() final  double sleepAlarmDeviceVolume;
@override@JsonKey() final  bool darkMode;
@override@JsonKey() final  bool linearSleepIn;
@override@JsonKey() final  bool linearWakeUp;
@override@JsonKey() final  bool useDynamicBlurhash;
@override@JsonKey() final  bool useAnimations;
@override@JsonKey() final  bool useLiquidGlass;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.market, market) || other.market == market)&&(identical(other.useSyncTimeDelay, useSyncTimeDelay) || other.useSyncTimeDelay == useSyncTimeDelay)&&(identical(other.useSyncedLyrics, useSyncedLyrics) || other.useSyncedLyrics == useSyncedLyrics)&&(identical(other.searchArtistCount, searchArtistCount) || other.searchArtistCount == searchArtistCount)&&(identical(other.searchAlbumCount, searchAlbumCount) || other.searchAlbumCount == searchAlbumCount)&&(identical(other.searchTrackCount, searchTrackCount) || other.searchTrackCount == searchTrackCount)&&(identical(other.searchPlaylistCount, searchPlaylistCount) || other.searchPlaylistCount == searchPlaylistCount)&&(identical(other.lyricsTextAlign, lyricsTextAlign) || other.lyricsTextAlign == lyricsTextAlign)&&(identical(other.useCacheAudioSource, useCacheAudioSource) || other.useCacheAudioSource == useCacheAudioSource)&&(identical(other.enableLyrics, enableLyrics) || other.enableLyrics == enableLyrics)&&(identical(other.enableHistory, enableHistory) || other.enableHistory == enableHistory)&&(identical(other.enableCategories, enableCategories) || other.enableCategories == enableCategories)&&(identical(other.categoryCount, categoryCount) || other.categoryCount == categoryCount)&&(identical(other.cacheImages, cacheImages) || other.cacheImages == cacheImages)&&(identical(other.localsSort, localsSort) || other.localsSort == localsSort)&&(identical(other.useBlur, useBlur) || other.useBlur == useBlur)&&(identical(other.useMix, useMix) || other.useMix == useMix)&&(identical(other.useDetailedBlurhash, useDetailedBlurhash) || other.useDetailedBlurhash == useDetailedBlurhash)&&(identical(other.sleepAlarmDeviceVolume, sleepAlarmDeviceVolume) || other.sleepAlarmDeviceVolume == sleepAlarmDeviceVolume)&&(identical(other.darkMode, darkMode) || other.darkMode == darkMode)&&(identical(other.linearSleepIn, linearSleepIn) || other.linearSleepIn == linearSleepIn)&&(identical(other.linearWakeUp, linearWakeUp) || other.linearWakeUp == linearWakeUp)&&(identical(other.useDynamicBlurhash, useDynamicBlurhash) || other.useDynamicBlurhash == useDynamicBlurhash)&&(identical(other.useAnimations, useAnimations) || other.useAnimations == useAnimations)&&(identical(other.useLiquidGlass, useLiquidGlass) || other.useLiquidGlass == useLiquidGlass));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,locale,market,useSyncTimeDelay,useSyncedLyrics,searchArtistCount,searchAlbumCount,searchTrackCount,searchPlaylistCount,lyricsTextAlign,useCacheAudioSource,enableLyrics,enableHistory,enableCategories,categoryCount,cacheImages,localsSort,useBlur,useMix,useDetailedBlurhash,sleepAlarmDeviceVolume,darkMode,linearSleepIn,linearWakeUp,useDynamicBlurhash,useAnimations,useLiquidGlass]);
}

@override
String toString() {
    return 'AppSettings(locale: $locale, market: $market, useSyncTimeDelay: $useSyncTimeDelay, useSyncedLyrics: $useSyncedLyrics, searchArtistCount: $searchArtistCount, searchAlbumCount: $searchAlbumCount, searchTrackCount: $searchTrackCount, searchPlaylistCount: $searchPlaylistCount, lyricsTextAlign: $lyricsTextAlign, useCacheAudioSource: $useCacheAudioSource, enableLyrics: $enableLyrics, enableHistory: $enableHistory, enableCategories: $enableCategories, categoryCount: $categoryCount, cacheImages: $cacheImages, localsSort: $localsSort, useBlur: $useBlur, useMix: $useMix, useDetailedBlurhash: $useDetailedBlurhash, sleepAlarmDeviceVolume: $sleepAlarmDeviceVolume, darkMode: $darkMode, linearSleepIn: $linearSleepIn, linearWakeUp: $linearWakeUp, useDynamicBlurhash: $useDynamicBlurhash, useAnimations: $useAnimations, useLiquidGlass: $useLiquidGlass)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String locale, String market, bool useSyncTimeDelay, bool useSyncedLyrics, int searchArtistCount, int searchAlbumCount, int searchTrackCount, int searchPlaylistCount, TextAlign lyricsTextAlign, bool useCacheAudioSource, bool enableLyrics, bool enableHistory, bool enableCategories, int categoryCount, bool cacheImages, LocalsSort localsSort, bool useBlur, bool useMix, bool useDetailedBlurhash, double sleepAlarmDeviceVolume, bool darkMode, bool linearSleepIn, bool linearWakeUp, bool useDynamicBlurhash, bool useAnimations, bool useLiquidGlass
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locale = null,Object? market = null,Object? useSyncTimeDelay = null,Object? useSyncedLyrics = null,Object? searchArtistCount = null,Object? searchAlbumCount = null,Object? searchTrackCount = null,Object? searchPlaylistCount = null,Object? lyricsTextAlign = null,Object? useCacheAudioSource = null,Object? enableLyrics = null,Object? enableHistory = null,Object? enableCategories = null,Object? categoryCount = null,Object? cacheImages = null,Object? localsSort = null,Object? useBlur = null,Object? useMix = null,Object? useDetailedBlurhash = null,Object? sleepAlarmDeviceVolume = null,Object? darkMode = null,Object? linearSleepIn = null,Object? linearWakeUp = null,Object? useDynamicBlurhash = null,Object? useAnimations = null,Object? useLiquidGlass = null,}) {
  return _then(_AppSettings(
locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,useSyncTimeDelay: null == useSyncTimeDelay ? _self.useSyncTimeDelay : useSyncTimeDelay // ignore: cast_nullable_to_non_nullable
as bool,useSyncedLyrics: null == useSyncedLyrics ? _self.useSyncedLyrics : useSyncedLyrics // ignore: cast_nullable_to_non_nullable
as bool,searchArtistCount: null == searchArtistCount ? _self.searchArtistCount : searchArtistCount // ignore: cast_nullable_to_non_nullable
as int,searchAlbumCount: null == searchAlbumCount ? _self.searchAlbumCount : searchAlbumCount // ignore: cast_nullable_to_non_nullable
as int,searchTrackCount: null == searchTrackCount ? _self.searchTrackCount : searchTrackCount // ignore: cast_nullable_to_non_nullable
as int,searchPlaylistCount: null == searchPlaylistCount ? _self.searchPlaylistCount : searchPlaylistCount // ignore: cast_nullable_to_non_nullable
as int,lyricsTextAlign: null == lyricsTextAlign ? _self.lyricsTextAlign : lyricsTextAlign // ignore: cast_nullable_to_non_nullable
as TextAlign,useCacheAudioSource: null == useCacheAudioSource ? _self.useCacheAudioSource : useCacheAudioSource // ignore: cast_nullable_to_non_nullable
as bool,enableLyrics: null == enableLyrics ? _self.enableLyrics : enableLyrics // ignore: cast_nullable_to_non_nullable
as bool,enableHistory: null == enableHistory ? _self.enableHistory : enableHistory // ignore: cast_nullable_to_non_nullable
as bool,enableCategories: null == enableCategories ? _self.enableCategories : enableCategories // ignore: cast_nullable_to_non_nullable
as bool,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,cacheImages: null == cacheImages ? _self.cacheImages : cacheImages // ignore: cast_nullable_to_non_nullable
as bool,localsSort: null == localsSort ? _self.localsSort : localsSort // ignore: cast_nullable_to_non_nullable
as LocalsSort,useBlur: null == useBlur ? _self.useBlur : useBlur // ignore: cast_nullable_to_non_nullable
as bool,useMix: null == useMix ? _self.useMix : useMix // ignore: cast_nullable_to_non_nullable
as bool,useDetailedBlurhash: null == useDetailedBlurhash ? _self.useDetailedBlurhash : useDetailedBlurhash // ignore: cast_nullable_to_non_nullable
as bool,sleepAlarmDeviceVolume: null == sleepAlarmDeviceVolume ? _self.sleepAlarmDeviceVolume : sleepAlarmDeviceVolume // ignore: cast_nullable_to_non_nullable
as double,darkMode: null == darkMode ? _self.darkMode : darkMode // ignore: cast_nullable_to_non_nullable
as bool,linearSleepIn: null == linearSleepIn ? _self.linearSleepIn : linearSleepIn // ignore: cast_nullable_to_non_nullable
as bool,linearWakeUp: null == linearWakeUp ? _self.linearWakeUp : linearWakeUp // ignore: cast_nullable_to_non_nullable
as bool,useDynamicBlurhash: null == useDynamicBlurhash ? _self.useDynamicBlurhash : useDynamicBlurhash // ignore: cast_nullable_to_non_nullable
as bool,useAnimations: null == useAnimations ? _self.useAnimations : useAnimations // ignore: cast_nullable_to_non_nullable
as bool,useLiquidGlass: null == useLiquidGlass ? _self.useLiquidGlass : useLiquidGlass // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
