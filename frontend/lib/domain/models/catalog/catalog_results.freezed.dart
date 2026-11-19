// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_results.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackAvailabilityMap {

/// Length in seconds of each track the server already has.
 Map<String, double> get durations;/// IDs of the tracks the server has to fetch first.
 List<String> get missing;
/// Create a copy of TrackAvailabilityMap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackAvailabilityMapCopyWith<TrackAvailabilityMap> get copyWith => _$TrackAvailabilityMapCopyWithImpl<TrackAvailabilityMap>(this as TrackAvailabilityMap, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackAvailabilityMap;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackAvailabilityMap&&const DeepCollectionEquality().equals(other.durations, _this.durations)&&const DeepCollectionEquality().equals(other.missing, _this.missing));
}


@override
int get hashCode {
  final _this = this as TrackAvailabilityMap;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.durations),const DeepCollectionEquality().hash(_this.missing));
}

@override
String toString() {
  final _this = this as TrackAvailabilityMap;
  return 'TrackAvailabilityMap(durations: ${_this.durations}, missing: ${_this.missing})';
}


}

/// @nodoc
abstract mixin class $TrackAvailabilityMapCopyWith<$Res>  {
  factory $TrackAvailabilityMapCopyWith(TrackAvailabilityMap value, $Res Function(TrackAvailabilityMap) _then) = _$TrackAvailabilityMapCopyWithImpl;
@useResult
$Res call({
 Map<String, double> durations, List<String> missing
});




}
/// @nodoc
class _$TrackAvailabilityMapCopyWithImpl<$Res>
    implements $TrackAvailabilityMapCopyWith<$Res> {
  _$TrackAvailabilityMapCopyWithImpl(this._self, this._then);

  final TrackAvailabilityMap _self;
  final $Res Function(TrackAvailabilityMap) _then;

/// Create a copy of TrackAvailabilityMap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? durations = null,Object? missing = null,}) {
  return _then(TrackAvailabilityMap(
durations: null == durations ? _self.durations : durations // ignore: cast_nullable_to_non_nullable
as Map<String, double>,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackAvailabilityMap].
extension TrackAvailabilityMapPatterns on TrackAvailabilityMap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackAvailabilityMap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackAvailabilityMap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackAvailabilityMap value)  $default,){
final _that = this;
switch (_that) {
case _TrackAvailabilityMap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackAvailabilityMap value)?  $default,){
final _that = this;
switch (_that) {
case _TrackAvailabilityMap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, double> durations,  List<String> missing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackAvailabilityMap() when $default != null:
return $default(_that.durations,_that.missing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, double> durations,  List<String> missing)  $default,) {final _that = this;
switch (_that) {
case _TrackAvailabilityMap():
return $default(_that.durations,_that.missing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, double> durations,  List<String> missing)?  $default,) {final _that = this;
switch (_that) {
case _TrackAvailabilityMap() when $default != null:
return $default(_that.durations,_that.missing);case _:
  return null;

}
}

}

/// @nodoc


class _TrackAvailabilityMap implements TrackAvailabilityMap {
  const _TrackAvailabilityMap({required  Map<String, double> durations, required  List<String> missing}): _durations = durations,_missing = missing;
  

/// Length in seconds of each track the server already has.
 final  Map<String, double> _durations;
/// Length in seconds of each track the server already has.
@override Map<String, double> get durations {
  if (_durations is EqualUnmodifiableMapView) return _durations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_durations);
}

/// IDs of the tracks the server has to fetch first.
 final  List<String> _missing;
/// IDs of the tracks the server has to fetch first.
@override List<String> get missing {
  if (_missing is EqualUnmodifiableListView) return _missing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missing);
}


/// Create a copy of TrackAvailabilityMap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackAvailabilityMapCopyWith<_TrackAvailabilityMap> get copyWith => __$TrackAvailabilityMapCopyWithImpl<_TrackAvailabilityMap>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackAvailabilityMap&&const DeepCollectionEquality().equals(other.durations, _durations)&&const DeepCollectionEquality().equals(other.missing, _missing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_durations),const DeepCollectionEquality().hash(_missing));
}

@override
String toString() {
    return 'TrackAvailabilityMap(durations: $durations, missing: $missing)';
}


}

/// @nodoc
abstract mixin class _$TrackAvailabilityMapCopyWith<$Res> implements $TrackAvailabilityMapCopyWith<$Res> {
  factory _$TrackAvailabilityMapCopyWith(_TrackAvailabilityMap value, $Res Function(_TrackAvailabilityMap) _then) = __$TrackAvailabilityMapCopyWithImpl;
@override @useResult
$Res call({
 Map<String, double> durations, List<String> missing
});




}
/// @nodoc
class __$TrackAvailabilityMapCopyWithImpl<$Res>
    implements _$TrackAvailabilityMapCopyWith<$Res> {
  __$TrackAvailabilityMapCopyWithImpl(this._self, this._then);

  final _TrackAvailabilityMap _self;
  final $Res Function(_TrackAvailabilityMap) _then;

/// Create a copy of TrackAvailabilityMap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? durations = null,Object? missing = null,}) {
  return _then(_TrackAvailabilityMap(
durations: null == durations ? _self._durations : durations // ignore: cast_nullable_to_non_nullable
as Map<String, double>,missing: null == missing ? _self._missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$TrackListing {

 List<Track> get tracks; TrackAvailabilityMap get availability;
/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackListingCopyWith<TrackListing> get copyWith => _$TrackListingCopyWithImpl<TrackListing>(this as TrackListing, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackListing;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackListing&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.availability, _this.availability) || other.availability == _this.availability));
}


@override
int get hashCode {
  final _this = this as TrackListing;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.tracks),_this.availability);
}

@override
String toString() {
  final _this = this as TrackListing;
  return 'TrackListing(tracks: ${_this.tracks}, availability: ${_this.availability})';
}


}

/// @nodoc
abstract mixin class $TrackListingCopyWith<$Res>  {
  factory $TrackListingCopyWith(TrackListing value, $Res Function(TrackListing) _then) = _$TrackListingCopyWithImpl;
@useResult
$Res call({
 List<Track> tracks, TrackAvailabilityMap availability
});


$TrackAvailabilityMapCopyWith<$Res> get availability;

}
/// @nodoc
class _$TrackListingCopyWithImpl<$Res>
    implements $TrackListingCopyWith<$Res> {
  _$TrackListingCopyWithImpl(this._self, this._then);

  final TrackListing _self;
  final $Res Function(TrackListing) _then;

/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,Object? availability = null,}) {
  return _then(TrackListing(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as TrackAvailabilityMap,
  ));
}
/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackAvailabilityMapCopyWith<$Res> get availability {
  
  return $TrackAvailabilityMapCopyWith<$Res>(_self.availability, (value) {
    return _then(_self.copyWith(availability: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackListing].
extension TrackListingPatterns on TrackListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackListing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackListing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackListing value)  $default,){
final _that = this;
switch (_that) {
case _TrackListing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackListing value)?  $default,){
final _that = this;
switch (_that) {
case _TrackListing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Track> tracks,  TrackAvailabilityMap availability)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackListing() when $default != null:
return $default(_that.tracks,_that.availability);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Track> tracks,  TrackAvailabilityMap availability)  $default,) {final _that = this;
switch (_that) {
case _TrackListing():
return $default(_that.tracks,_that.availability);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Track> tracks,  TrackAvailabilityMap availability)?  $default,) {final _that = this;
switch (_that) {
case _TrackListing() when $default != null:
return $default(_that.tracks,_that.availability);case _:
  return null;

}
}

}

/// @nodoc


class _TrackListing implements TrackListing {
  const _TrackListing({required  List<Track> tracks, required this.availability}): _tracks = tracks;
  

 final  List<Track> _tracks;
@override List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

@override final  TrackAvailabilityMap availability;

/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackListingCopyWith<_TrackListing> get copyWith => __$TrackListingCopyWithImpl<_TrackListing>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackListing&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),availability);
}

@override
String toString() {
    return 'TrackListing(tracks: $tracks, availability: $availability)';
}


}

/// @nodoc
abstract mixin class _$TrackListingCopyWith<$Res> implements $TrackListingCopyWith<$Res> {
  factory _$TrackListingCopyWith(_TrackListing value, $Res Function(_TrackListing) _then) = __$TrackListingCopyWithImpl;
@override @useResult
$Res call({
 List<Track> tracks, TrackAvailabilityMap availability
});


@override $TrackAvailabilityMapCopyWith<$Res> get availability;

}
/// @nodoc
class __$TrackListingCopyWithImpl<$Res>
    implements _$TrackListingCopyWith<$Res> {
  __$TrackListingCopyWithImpl(this._self, this._then);

  final _TrackListing _self;
  final $Res Function(_TrackListing) _then;

/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? availability = null,}) {
  return _then(_TrackListing(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as TrackAvailabilityMap,
  ));
}

/// Create a copy of TrackListing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackAvailabilityMapCopyWith<$Res> get availability {
  
  return $TrackAvailabilityMapCopyWith<$Res>(_self.availability, (value) {
    return _then(_self.copyWith(availability: value));
  });
}
}

/// @nodoc
mixin _$ArtistDetails {

/// Full length albums.
 List<Album> get albums;/// Singles, EPs and compilations.
 List<Album> get otherReleases; List<Track> get tracks;
/// Create a copy of ArtistDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistDetailsCopyWith<ArtistDetails> get copyWith => _$ArtistDetailsCopyWithImpl<ArtistDetails>(this as ArtistDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistDetails&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.otherReleases, _this.otherReleases)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks));
}


@override
int get hashCode {
  final _this = this as ArtistDetails;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.otherReleases),const DeepCollectionEquality().hash(_this.tracks));
}

@override
String toString() {
  final _this = this as ArtistDetails;
  return 'ArtistDetails(albums: ${_this.albums}, otherReleases: ${_this.otherReleases}, tracks: ${_this.tracks})';
}


}

/// @nodoc
abstract mixin class $ArtistDetailsCopyWith<$Res>  {
  factory $ArtistDetailsCopyWith(ArtistDetails value, $Res Function(ArtistDetails) _then) = _$ArtistDetailsCopyWithImpl;
@useResult
$Res call({
 List<Album> albums, List<Album> otherReleases, List<Track> tracks
});




}
/// @nodoc
class _$ArtistDetailsCopyWithImpl<$Res>
    implements $ArtistDetailsCopyWith<$Res> {
  _$ArtistDetailsCopyWithImpl(this._self, this._then);

  final ArtistDetails _self;
  final $Res Function(ArtistDetails) _then;

/// Create a copy of ArtistDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albums = null,Object? otherReleases = null,Object? tracks = null,}) {
  return _then(ArtistDetails(
albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,otherReleases: null == otherReleases ? _self.otherReleases : otherReleases // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistDetails].
extension ArtistDetailsPatterns on ArtistDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistDetails value)  $default,){
final _that = this;
switch (_that) {
case _ArtistDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Album> albums,  List<Album> otherReleases,  List<Track> tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistDetails() when $default != null:
return $default(_that.albums,_that.otherReleases,_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Album> albums,  List<Album> otherReleases,  List<Track> tracks)  $default,) {final _that = this;
switch (_that) {
case _ArtistDetails():
return $default(_that.albums,_that.otherReleases,_that.tracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Album> albums,  List<Album> otherReleases,  List<Track> tracks)?  $default,) {final _that = this;
switch (_that) {
case _ArtistDetails() when $default != null:
return $default(_that.albums,_that.otherReleases,_that.tracks);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistDetails implements ArtistDetails {
  const _ArtistDetails({required  List<Album> albums, required  List<Album> otherReleases, required  List<Track> tracks}): _albums = albums,_otherReleases = otherReleases,_tracks = tracks;
  

/// Full length albums.
 final  List<Album> _albums;
/// Full length albums.
@override List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

/// Singles, EPs and compilations.
 final  List<Album> _otherReleases;
/// Singles, EPs and compilations.
@override List<Album> get otherReleases {
  if (_otherReleases is EqualUnmodifiableListView) return _otherReleases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_otherReleases);
}

 final  List<Track> _tracks;
@override List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}


/// Create a copy of ArtistDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistDetailsCopyWith<_ArtistDetails> get copyWith => __$ArtistDetailsCopyWithImpl<_ArtistDetails>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistDetails&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.otherReleases, _otherReleases)&&const DeepCollectionEquality().equals(other.tracks, _tracks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_otherReleases),const DeepCollectionEquality().hash(_tracks));
}

@override
String toString() {
    return 'ArtistDetails(albums: $albums, otherReleases: $otherReleases, tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$ArtistDetailsCopyWith<$Res> implements $ArtistDetailsCopyWith<$Res> {
  factory _$ArtistDetailsCopyWith(_ArtistDetails value, $Res Function(_ArtistDetails) _then) = __$ArtistDetailsCopyWithImpl;
@override @useResult
$Res call({
 List<Album> albums, List<Album> otherReleases, List<Track> tracks
});




}
/// @nodoc
class __$ArtistDetailsCopyWithImpl<$Res>
    implements _$ArtistDetailsCopyWith<$Res> {
  __$ArtistDetailsCopyWithImpl(this._self, this._then);

  final _ArtistDetails _self;
  final $Res Function(_ArtistDetails) _then;

/// Create a copy of ArtistDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? albums = null,Object? otherReleases = null,Object? tracks = null,}) {
  return _then(_ArtistDetails(
albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,otherReleases: null == otherReleases ? _self._otherReleases : otherReleases // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}


}

/// @nodoc
mixin _$SearchResults {

 List<Track> get tracks; List<Artist> get artists; List<Album> get albums; List<Playlist> get playlists;
/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultsCopyWith<SearchResults> get copyWith => _$SearchResultsCopyWithImpl<SearchResults>(this as SearchResults, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchResults;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResults&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.playlists, _this.playlists));
}


@override
int get hashCode {
  final _this = this as SearchResults;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.artists),const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.playlists));
}

@override
String toString() {
  final _this = this as SearchResults;
  return 'SearchResults(tracks: ${_this.tracks}, artists: ${_this.artists}, albums: ${_this.albums}, playlists: ${_this.playlists})';
}


}

/// @nodoc
abstract mixin class $SearchResultsCopyWith<$Res>  {
  factory $SearchResultsCopyWith(SearchResults value, $Res Function(SearchResults) _then) = _$SearchResultsCopyWithImpl;
@useResult
$Res call({
 List<Track> tracks, List<Artist> artists, List<Album> albums, List<Playlist> playlists
});




}
/// @nodoc
class _$SearchResultsCopyWithImpl<$Res>
    implements $SearchResultsCopyWith<$Res> {
  _$SearchResultsCopyWithImpl(this._self, this._then);

  final SearchResults _self;
  final $Res Function(SearchResults) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,Object? artists = null,Object? albums = null,Object? playlists = null,}) {
  return _then(SearchResults(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,playlists: null == playlists ? _self.playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResults].
extension SearchResultsPatterns on SearchResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResults value)  $default,){
final _that = this;
switch (_that) {
case _SearchResults():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResults value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Track> tracks,  List<Artist> artists,  List<Album> albums,  List<Playlist> playlists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
return $default(_that.tracks,_that.artists,_that.albums,_that.playlists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Track> tracks,  List<Artist> artists,  List<Album> albums,  List<Playlist> playlists)  $default,) {final _that = this;
switch (_that) {
case _SearchResults():
return $default(_that.tracks,_that.artists,_that.albums,_that.playlists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Track> tracks,  List<Artist> artists,  List<Album> albums,  List<Playlist> playlists)?  $default,) {final _that = this;
switch (_that) {
case _SearchResults() when $default != null:
return $default(_that.tracks,_that.artists,_that.albums,_that.playlists);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResults implements SearchResults {
  const _SearchResults({ List<Track> tracks = const <Track>[],  List<Artist> artists = const <Artist>[],  List<Album> albums = const <Album>[],  List<Playlist> playlists = const <Playlist>[]}): _tracks = tracks,_artists = artists,_albums = albums,_playlists = playlists;
  

 final  List<Track> _tracks;
@override@JsonKey() List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

 final  List<Artist> _artists;
@override@JsonKey() List<Artist> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

 final  List<Album> _albums;
@override@JsonKey() List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

 final  List<Playlist> _playlists;
@override@JsonKey() List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultsCopyWith<_SearchResults> get copyWith => __$SearchResultsCopyWithImpl<_SearchResults>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResults&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&const DeepCollectionEquality().equals(other.artists, _artists)&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.playlists, _playlists));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_playlists));
}

@override
String toString() {
    return 'SearchResults(tracks: $tracks, artists: $artists, albums: $albums, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class _$SearchResultsCopyWith<$Res> implements $SearchResultsCopyWith<$Res> {
  factory _$SearchResultsCopyWith(_SearchResults value, $Res Function(_SearchResults) _then) = __$SearchResultsCopyWithImpl;
@override @useResult
$Res call({
 List<Track> tracks, List<Artist> artists, List<Album> albums, List<Playlist> playlists
});




}
/// @nodoc
class __$SearchResultsCopyWithImpl<$Res>
    implements _$SearchResultsCopyWith<$Res> {
  __$SearchResultsCopyWithImpl(this._self, this._then);

  final _SearchResults _self;
  final $Res Function(_SearchResults) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? artists = null,Object? albums = null,Object? playlists = null,}) {
  return _then(_SearchResults(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc
mixin _$HomeFeed {

/// Tracks recommended from the play history.
 List<Track> get history; List<SpCategory> get categories; List<Album> get newReleases; List<Track> get topTracks; List<Artist> get topArtists; List<Playlist> get topPlaylists;
/// Create a copy of HomeFeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeFeedCopyWith<HomeFeed> get copyWith => _$HomeFeedCopyWithImpl<HomeFeed>(this as HomeFeed, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HomeFeed;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeFeed&&const DeepCollectionEquality().equals(other.history, _this.history)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.newReleases, _this.newReleases)&&const DeepCollectionEquality().equals(other.topTracks, _this.topTracks)&&const DeepCollectionEquality().equals(other.topArtists, _this.topArtists)&&const DeepCollectionEquality().equals(other.topPlaylists, _this.topPlaylists));
}


@override
int get hashCode {
  final _this = this as HomeFeed;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.history),const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.newReleases),const DeepCollectionEquality().hash(_this.topTracks),const DeepCollectionEquality().hash(_this.topArtists),const DeepCollectionEquality().hash(_this.topPlaylists));
}

@override
String toString() {
  final _this = this as HomeFeed;
  return 'HomeFeed(history: ${_this.history}, categories: ${_this.categories}, newReleases: ${_this.newReleases}, topTracks: ${_this.topTracks}, topArtists: ${_this.topArtists}, topPlaylists: ${_this.topPlaylists})';
}


}

/// @nodoc
abstract mixin class $HomeFeedCopyWith<$Res>  {
  factory $HomeFeedCopyWith(HomeFeed value, $Res Function(HomeFeed) _then) = _$HomeFeedCopyWithImpl;
@useResult
$Res call({
 List<Track> history, List<SpCategory> categories, List<Album> newReleases, List<Track> topTracks, List<Artist> topArtists, List<Playlist> topPlaylists
});




}
/// @nodoc
class _$HomeFeedCopyWithImpl<$Res>
    implements $HomeFeedCopyWith<$Res> {
  _$HomeFeedCopyWithImpl(this._self, this._then);

  final HomeFeed _self;
  final $Res Function(HomeFeed) _then;

/// Create a copy of HomeFeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? history = null,Object? categories = null,Object? newReleases = null,Object? topTracks = null,Object? topArtists = null,Object? topPlaylists = null,}) {
  return _then(HomeFeed(
history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<Track>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<SpCategory>,newReleases: null == newReleases ? _self.newReleases : newReleases // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self.topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,topArtists: null == topArtists ? _self.topArtists : topArtists // ignore: cast_nullable_to_non_nullable
as List<Artist>,topPlaylists: null == topPlaylists ? _self.topPlaylists : topPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeFeed].
extension HomeFeedPatterns on HomeFeed {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeFeed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeFeed() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeFeed value)  $default,){
final _that = this;
switch (_that) {
case _HomeFeed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeFeed value)?  $default,){
final _that = this;
switch (_that) {
case _HomeFeed() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Track> history,  List<SpCategory> categories,  List<Album> newReleases,  List<Track> topTracks,  List<Artist> topArtists,  List<Playlist> topPlaylists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeFeed() when $default != null:
return $default(_that.history,_that.categories,_that.newReleases,_that.topTracks,_that.topArtists,_that.topPlaylists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Track> history,  List<SpCategory> categories,  List<Album> newReleases,  List<Track> topTracks,  List<Artist> topArtists,  List<Playlist> topPlaylists)  $default,) {final _that = this;
switch (_that) {
case _HomeFeed():
return $default(_that.history,_that.categories,_that.newReleases,_that.topTracks,_that.topArtists,_that.topPlaylists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Track> history,  List<SpCategory> categories,  List<Album> newReleases,  List<Track> topTracks,  List<Artist> topArtists,  List<Playlist> topPlaylists)?  $default,) {final _that = this;
switch (_that) {
case _HomeFeed() when $default != null:
return $default(_that.history,_that.categories,_that.newReleases,_that.topTracks,_that.topArtists,_that.topPlaylists);case _:
  return null;

}
}

}

/// @nodoc


class _HomeFeed implements HomeFeed {
  const _HomeFeed({ List<Track> history = const <Track>[],  List<SpCategory> categories = const <SpCategory>[],  List<Album> newReleases = const <Album>[],  List<Track> topTracks = const <Track>[],  List<Artist> topArtists = const <Artist>[],  List<Playlist> topPlaylists = const <Playlist>[]}): _history = history,_categories = categories,_newReleases = newReleases,_topTracks = topTracks,_topArtists = topArtists,_topPlaylists = topPlaylists;
  

/// Tracks recommended from the play history.
 final  List<Track> _history;
/// Tracks recommended from the play history.
@override@JsonKey() List<Track> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

 final  List<SpCategory> _categories;
@override@JsonKey() List<SpCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<Album> _newReleases;
@override@JsonKey() List<Album> get newReleases {
  if (_newReleases is EqualUnmodifiableListView) return _newReleases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newReleases);
}

 final  List<Track> _topTracks;
@override@JsonKey() List<Track> get topTracks {
  if (_topTracks is EqualUnmodifiableListView) return _topTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTracks);
}

 final  List<Artist> _topArtists;
@override@JsonKey() List<Artist> get topArtists {
  if (_topArtists is EqualUnmodifiableListView) return _topArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topArtists);
}

 final  List<Playlist> _topPlaylists;
@override@JsonKey() List<Playlist> get topPlaylists {
  if (_topPlaylists is EqualUnmodifiableListView) return _topPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topPlaylists);
}


/// Create a copy of HomeFeed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeFeedCopyWith<_HomeFeed> get copyWith => __$HomeFeedCopyWithImpl<_HomeFeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeFeed&&const DeepCollectionEquality().equals(other.history, _history)&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.newReleases, _newReleases)&&const DeepCollectionEquality().equals(other.topTracks, _topTracks)&&const DeepCollectionEquality().equals(other.topArtists, _topArtists)&&const DeepCollectionEquality().equals(other.topPlaylists, _topPlaylists));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_history),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_newReleases),const DeepCollectionEquality().hash(_topTracks),const DeepCollectionEquality().hash(_topArtists),const DeepCollectionEquality().hash(_topPlaylists));
}

@override
String toString() {
    return 'HomeFeed(history: $history, categories: $categories, newReleases: $newReleases, topTracks: $topTracks, topArtists: $topArtists, topPlaylists: $topPlaylists)';
}


}

/// @nodoc
abstract mixin class _$HomeFeedCopyWith<$Res> implements $HomeFeedCopyWith<$Res> {
  factory _$HomeFeedCopyWith(_HomeFeed value, $Res Function(_HomeFeed) _then) = __$HomeFeedCopyWithImpl;
@override @useResult
$Res call({
 List<Track> history, List<SpCategory> categories, List<Album> newReleases, List<Track> topTracks, List<Artist> topArtists, List<Playlist> topPlaylists
});




}
/// @nodoc
class __$HomeFeedCopyWithImpl<$Res>
    implements _$HomeFeedCopyWith<$Res> {
  __$HomeFeedCopyWithImpl(this._self, this._then);

  final _HomeFeed _self;
  final $Res Function(_HomeFeed) _then;

/// Create a copy of HomeFeed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? history = null,Object? categories = null,Object? newReleases = null,Object? topTracks = null,Object? topArtists = null,Object? topPlaylists = null,}) {
  return _then(_HomeFeed(
history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<Track>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<SpCategory>,newReleases: null == newReleases ? _self._newReleases : newReleases // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self._topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,topArtists: null == topArtists ? _self._topArtists : topArtists // ignore: cast_nullable_to_non_nullable
as List<Artist>,topPlaylists: null == topPlaylists ? _self._topPlaylists : topPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc
mixin _$ShazamMatch {

 String get title; String get subtitle;/// URL of the cover art.
 String get coverArt;
/// Create a copy of ShazamMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShazamMatchCopyWith<ShazamMatch> get copyWith => _$ShazamMatchCopyWithImpl<ShazamMatch>(this as ShazamMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShazamMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShazamMatch&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt));
}


@override
int get hashCode {
  final _this = this as ShazamMatch;
  return Object.hash(runtimeType,_this.title,_this.subtitle,_this.coverArt);
}

@override
String toString() {
  final _this = this as ShazamMatch;
  return 'ShazamMatch(title: ${_this.title}, subtitle: ${_this.subtitle}, coverArt: ${_this.coverArt})';
}


}

/// @nodoc
abstract mixin class $ShazamMatchCopyWith<$Res>  {
  factory $ShazamMatchCopyWith(ShazamMatch value, $Res Function(ShazamMatch) _then) = _$ShazamMatchCopyWithImpl;
@useResult
$Res call({
 String title, String subtitle, String coverArt
});




}
/// @nodoc
class _$ShazamMatchCopyWithImpl<$Res>
    implements $ShazamMatchCopyWith<$Res> {
  _$ShazamMatchCopyWithImpl(this._self, this._then);

  final ShazamMatch _self;
  final $Res Function(ShazamMatch) _then;

/// Create a copy of ShazamMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? subtitle = null,Object? coverArt = null,}) {
  return _then(ShazamMatch(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,coverArt: null == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShazamMatch].
extension ShazamMatchPatterns on ShazamMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShazamMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShazamMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShazamMatch value)  $default,){
final _that = this;
switch (_that) {
case _ShazamMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShazamMatch value)?  $default,){
final _that = this;
switch (_that) {
case _ShazamMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String subtitle,  String coverArt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShazamMatch() when $default != null:
return $default(_that.title,_that.subtitle,_that.coverArt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String subtitle,  String coverArt)  $default,) {final _that = this;
switch (_that) {
case _ShazamMatch():
return $default(_that.title,_that.subtitle,_that.coverArt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String subtitle,  String coverArt)?  $default,) {final _that = this;
switch (_that) {
case _ShazamMatch() when $default != null:
return $default(_that.title,_that.subtitle,_that.coverArt);case _:
  return null;

}
}

}

/// @nodoc


class _ShazamMatch implements ShazamMatch {
  const _ShazamMatch({required this.title, required this.subtitle, required this.coverArt});
  

@override final  String title;
@override final  String subtitle;
/// URL of the cover art.
@override final  String coverArt;

/// Create a copy of ShazamMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShazamMatchCopyWith<_ShazamMatch> get copyWith => __$ShazamMatchCopyWithImpl<_ShazamMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShazamMatch&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,subtitle,coverArt);
}

@override
String toString() {
    return 'ShazamMatch(title: $title, subtitle: $subtitle, coverArt: $coverArt)';
}


}

/// @nodoc
abstract mixin class _$ShazamMatchCopyWith<$Res> implements $ShazamMatchCopyWith<$Res> {
  factory _$ShazamMatchCopyWith(_ShazamMatch value, $Res Function(_ShazamMatch) _then) = __$ShazamMatchCopyWithImpl;
@override @useResult
$Res call({
 String title, String subtitle, String coverArt
});




}
/// @nodoc
class __$ShazamMatchCopyWithImpl<$Res>
    implements _$ShazamMatchCopyWith<$Res> {
  __$ShazamMatchCopyWithImpl(this._self, this._then);

  final _ShazamMatch _self;
  final $Res Function(_ShazamMatch) _then;

/// Create a copy of ShazamMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? subtitle = null,Object? coverArt = null,}) {
  return _then(_ShazamMatch(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,coverArt: null == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
