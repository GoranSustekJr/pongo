// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Track {

 String get id; String get name; List<ArtistTrack> get artists; AlbumTrack? get album; LocalImage? get image; TrackType get type;/// Path of the downloaded audio file, for offline tracks.
 String? get audio;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Track;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.audio, _this.audio) || other.audio == _this.audio));
}


@override
int get hashCode {
  final _this = this as Track;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.artists),_this.album,_this.image,_this.type,_this.audio);
}

@override
String toString() {
  final _this = this as Track;
  return 'Track(id: ${_this.id}, name: ${_this.name}, artists: ${_this.artists}, album: ${_this.album}, image: ${_this.image}, type: ${_this.type}, audio: ${_this.audio})';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<ArtistTrack> artists, AlbumTrack? album, LocalImage? image, TrackType type, String? audio
});


$AlbumTrackCopyWith<$Res>? get album;$LocalImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artists = null,Object? album = freezed,Object? image = freezed,Object? type = null,Object? audio = freezed,}) {
  return _then(Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as LocalImage?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TrackType,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumTrackCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $AlbumTrackCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $LocalImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<ArtistTrack> artists,  AlbumTrack? album,  LocalImage? image,  TrackType type,  String? audio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.name,_that.artists,_that.album,_that.image,_that.type,_that.audio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<ArtistTrack> artists,  AlbumTrack? album,  LocalImage? image,  TrackType type,  String? audio)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.id,_that.name,_that.artists,_that.album,_that.image,_that.type,_that.audio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<ArtistTrack> artists,  AlbumTrack? album,  LocalImage? image,  TrackType type,  String? audio)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.name,_that.artists,_that.album,_that.image,_that.type,_that.audio);case _:
  return null;

}
}

}

/// @nodoc


class _Track extends Track {
  const _Track({required this.id, required this.name, required  List<ArtistTrack> artists, required this.album, this.image, this.type = TrackType.online, this.audio}): _artists = artists,super._();
  

@override final  String id;
@override final  String name;
 final  List<ArtistTrack> _artists;
@override List<ArtistTrack> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

@override final  AlbumTrack? album;
@override final  LocalImage? image;
@override@JsonKey() final  TrackType type;
/// Path of the downloaded audio file, for offline tracks.
@override final  String? audio;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.artists, _artists)&&(identical(other.album, album) || other.album == album)&&(identical(other.image, image) || other.image == image)&&(identical(other.type, type) || other.type == type)&&(identical(other.audio, audio) || other.audio == audio));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_artists),album,image,type,audio);
}

@override
String toString() {
    return 'Track(id: $id, name: $name, artists: $artists, album: $album, image: $image, type: $type, audio: $audio)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<ArtistTrack> artists, AlbumTrack? album, LocalImage? image, TrackType type, String? audio
});


@override $AlbumTrackCopyWith<$Res>? get album;@override $LocalImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artists = null,Object? album = freezed,Object? image = freezed,Object? type = null,Object? audio = freezed,}) {
  return _then(_Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as LocalImage?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TrackType,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumTrackCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $AlbumTrackCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $LocalImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

/// @nodoc
mixin _$ArtistTrack {

 String get id; String? get name;
/// Create a copy of ArtistTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistTrackCopyWith<ArtistTrack> get copyWith => _$ArtistTrackCopyWithImpl<ArtistTrack>(this as ArtistTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as ArtistTrack;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as ArtistTrack;
  return 'ArtistTrack(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $ArtistTrackCopyWith<$Res>  {
  factory $ArtistTrackCopyWith(ArtistTrack value, $Res Function(ArtistTrack) _then) = _$ArtistTrackCopyWithImpl;
@useResult
$Res call({
 String id, String? name
});




}
/// @nodoc
class _$ArtistTrackCopyWithImpl<$Res>
    implements $ArtistTrackCopyWith<$Res> {
  _$ArtistTrackCopyWithImpl(this._self, this._then);

  final ArtistTrack _self;
  final $Res Function(ArtistTrack) _then;

/// Create a copy of ArtistTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(ArtistTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistTrack].
extension ArtistTrackPatterns on ArtistTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistTrack value)  $default,){
final _that = this;
switch (_that) {
case _ArtistTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistTrack value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistTrack() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _ArtistTrack():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _ArtistTrack() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistTrack extends ArtistTrack {
  const _ArtistTrack({required this.id, required this.name}): super._();
  

@override final  String id;
@override final  String? name;

/// Create a copy of ArtistTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistTrackCopyWith<_ArtistTrack> get copyWith => __$ArtistTrackCopyWithImpl<_ArtistTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'ArtistTrack(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ArtistTrackCopyWith<$Res> implements $ArtistTrackCopyWith<$Res> {
  factory _$ArtistTrackCopyWith(_ArtistTrack value, $Res Function(_ArtistTrack) _then) = __$ArtistTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name
});




}
/// @nodoc
class __$ArtistTrackCopyWithImpl<$Res>
    implements _$ArtistTrackCopyWith<$Res> {
  __$ArtistTrackCopyWithImpl(this._self, this._then);

  final _ArtistTrack _self;
  final $Res Function(_ArtistTrack) _then;

/// Create a copy of ArtistTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_ArtistTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AlbumTrack {

 String get id; String get name; List<AlbumImagesTrack> get images; String? get releaseDate;
/// Create a copy of AlbumTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumTrackCopyWith<AlbumTrack> get copyWith => _$AlbumTrackCopyWithImpl<AlbumTrack>(this as AlbumTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.images, _this.images)&&(identical(other.releaseDate, _this.releaseDate) || other.releaseDate == _this.releaseDate));
}


@override
int get hashCode {
  final _this = this as AlbumTrack;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.images),_this.releaseDate);
}

@override
String toString() {
  final _this = this as AlbumTrack;
  return 'AlbumTrack(id: ${_this.id}, name: ${_this.name}, images: ${_this.images}, releaseDate: ${_this.releaseDate})';
}


}

/// @nodoc
abstract mixin class $AlbumTrackCopyWith<$Res>  {
  factory $AlbumTrackCopyWith(AlbumTrack value, $Res Function(AlbumTrack) _then) = _$AlbumTrackCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<AlbumImagesTrack> images, String? releaseDate
});




}
/// @nodoc
class _$AlbumTrackCopyWithImpl<$Res>
    implements $AlbumTrackCopyWith<$Res> {
  _$AlbumTrackCopyWithImpl(this._self, this._then);

  final AlbumTrack _self;
  final $Res Function(AlbumTrack) _then;

/// Create a copy of AlbumTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? images = null,Object? releaseDate = freezed,}) {
  return _then(AlbumTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<AlbumImagesTrack>,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumTrack].
extension AlbumTrackPatterns on AlbumTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumTrack value)  $default,){
final _that = this;
switch (_that) {
case _AlbumTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumTrack value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<AlbumImagesTrack> images,  String? releaseDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumTrack() when $default != null:
return $default(_that.id,_that.name,_that.images,_that.releaseDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<AlbumImagesTrack> images,  String? releaseDate)  $default,) {final _that = this;
switch (_that) {
case _AlbumTrack():
return $default(_that.id,_that.name,_that.images,_that.releaseDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<AlbumImagesTrack> images,  String? releaseDate)?  $default,) {final _that = this;
switch (_that) {
case _AlbumTrack() when $default != null:
return $default(_that.id,_that.name,_that.images,_that.releaseDate);case _:
  return null;

}
}

}

/// @nodoc


class _AlbumTrack extends AlbumTrack {
  const _AlbumTrack({required this.id, required this.name, required  List<AlbumImagesTrack> images, required this.releaseDate}): _images = images,super._();
  

@override final  String id;
@override final  String name;
 final  List<AlbumImagesTrack> _images;
@override List<AlbumImagesTrack> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String? releaseDate;

/// Create a copy of AlbumTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumTrackCopyWith<_AlbumTrack> get copyWith => __$AlbumTrackCopyWithImpl<_AlbumTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, _images)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_images),releaseDate);
}

@override
String toString() {
    return 'AlbumTrack(id: $id, name: $name, images: $images, releaseDate: $releaseDate)';
}


}

/// @nodoc
abstract mixin class _$AlbumTrackCopyWith<$Res> implements $AlbumTrackCopyWith<$Res> {
  factory _$AlbumTrackCopyWith(_AlbumTrack value, $Res Function(_AlbumTrack) _then) = __$AlbumTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<AlbumImagesTrack> images, String? releaseDate
});




}
/// @nodoc
class __$AlbumTrackCopyWithImpl<$Res>
    implements _$AlbumTrackCopyWith<$Res> {
  __$AlbumTrackCopyWithImpl(this._self, this._then);

  final _AlbumTrack _self;
  final $Res Function(_AlbumTrack) _then;

/// Create a copy of AlbumTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? images = null,Object? releaseDate = freezed,}) {
  return _then(_AlbumTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<AlbumImagesTrack>,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AlbumImagesTrack {

 String get url; int? get height; int? get width;
/// Create a copy of AlbumImagesTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumImagesTrackCopyWith<AlbumImagesTrack> get copyWith => _$AlbumImagesTrackCopyWithImpl<AlbumImagesTrack>(this as AlbumImagesTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumImagesTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumImagesTrack&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.width, _this.width) || other.width == _this.width));
}


@override
int get hashCode {
  final _this = this as AlbumImagesTrack;
  return Object.hash(runtimeType,_this.url,_this.height,_this.width);
}

@override
String toString() {
  final _this = this as AlbumImagesTrack;
  return 'AlbumImagesTrack(url: ${_this.url}, height: ${_this.height}, width: ${_this.width})';
}


}

/// @nodoc
abstract mixin class $AlbumImagesTrackCopyWith<$Res>  {
  factory $AlbumImagesTrackCopyWith(AlbumImagesTrack value, $Res Function(AlbumImagesTrack) _then) = _$AlbumImagesTrackCopyWithImpl;
@useResult
$Res call({
 String url, int? height, int? width
});




}
/// @nodoc
class _$AlbumImagesTrackCopyWithImpl<$Res>
    implements $AlbumImagesTrackCopyWith<$Res> {
  _$AlbumImagesTrackCopyWithImpl(this._self, this._then);

  final AlbumImagesTrack _self;
  final $Res Function(AlbumImagesTrack) _then;

/// Create a copy of AlbumImagesTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? height = freezed,Object? width = freezed,}) {
  return _then(AlbumImagesTrack(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumImagesTrack].
extension AlbumImagesTrackPatterns on AlbumImagesTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumImagesTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumImagesTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumImagesTrack value)  $default,){
final _that = this;
switch (_that) {
case _AlbumImagesTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumImagesTrack value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumImagesTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int? height,  int? width)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumImagesTrack() when $default != null:
return $default(_that.url,_that.height,_that.width);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int? height,  int? width)  $default,) {final _that = this;
switch (_that) {
case _AlbumImagesTrack():
return $default(_that.url,_that.height,_that.width);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int? height,  int? width)?  $default,) {final _that = this;
switch (_that) {
case _AlbumImagesTrack() when $default != null:
return $default(_that.url,_that.height,_that.width);case _:
  return null;

}
}

}

/// @nodoc


class _AlbumImagesTrack extends AlbumImagesTrack {
  const _AlbumImagesTrack({required this.url, required this.height, required this.width}): super._();
  

@override final  String url;
@override final  int? height;
@override final  int? width;

/// Create a copy of AlbumImagesTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumImagesTrackCopyWith<_AlbumImagesTrack> get copyWith => __$AlbumImagesTrackCopyWithImpl<_AlbumImagesTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumImagesTrack&&(identical(other.url, url) || other.url == url)&&(identical(other.height, height) || other.height == height)&&(identical(other.width, width) || other.width == width));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,height,width);
}

@override
String toString() {
    return 'AlbumImagesTrack(url: $url, height: $height, width: $width)';
}


}

/// @nodoc
abstract mixin class _$AlbumImagesTrackCopyWith<$Res> implements $AlbumImagesTrackCopyWith<$Res> {
  factory _$AlbumImagesTrackCopyWith(_AlbumImagesTrack value, $Res Function(_AlbumImagesTrack) _then) = __$AlbumImagesTrackCopyWithImpl;
@override @useResult
$Res call({
 String url, int? height, int? width
});




}
/// @nodoc
class __$AlbumImagesTrackCopyWithImpl<$Res>
    implements _$AlbumImagesTrackCopyWith<$Res> {
  __$AlbumImagesTrackCopyWithImpl(this._self, this._then);

  final _AlbumImagesTrack _self;
  final $Res Function(_AlbumImagesTrack) _then;

/// Create a copy of AlbumImagesTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? height = freezed,Object? width = freezed,}) {
  return _then(_AlbumImagesTrack(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$LocalImage {

 String get path;
/// Create a copy of LocalImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalImageCopyWith<LocalImage> get copyWith => _$LocalImageCopyWithImpl<LocalImage>(this as LocalImage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalImage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalImage&&(identical(other.path, _this.path) || other.path == _this.path));
}


@override
int get hashCode {
  final _this = this as LocalImage;
  return Object.hash(runtimeType,_this.path);
}

@override
String toString() {
  final _this = this as LocalImage;
  return 'LocalImage(path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $LocalImageCopyWith<$Res>  {
  factory $LocalImageCopyWith(LocalImage value, $Res Function(LocalImage) _then) = _$LocalImageCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$LocalImageCopyWithImpl<$Res>
    implements $LocalImageCopyWith<$Res> {
  _$LocalImageCopyWithImpl(this._self, this._then);

  final LocalImage _self;
  final $Res Function(LocalImage) _then;

/// Create a copy of LocalImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,}) {
  return _then(LocalImage(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalImage].
extension LocalImagePatterns on LocalImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalImage value)  $default,){
final _that = this;
switch (_that) {
case _LocalImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalImage value)?  $default,){
final _that = this;
switch (_that) {
case _LocalImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalImage() when $default != null:
return $default(_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path)  $default,) {final _that = this;
switch (_that) {
case _LocalImage():
return $default(_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path)?  $default,) {final _that = this;
switch (_that) {
case _LocalImage() when $default != null:
return $default(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class _LocalImage implements LocalImage {
  const _LocalImage({required this.path});
  

@override final  String path;

/// Create a copy of LocalImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalImageCopyWith<_LocalImage> get copyWith => __$LocalImageCopyWithImpl<_LocalImage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalImage&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'LocalImage(path: $path)';
}


}

/// @nodoc
abstract mixin class _$LocalImageCopyWith<$Res> implements $LocalImageCopyWith<$Res> {
  factory _$LocalImageCopyWith(_LocalImage value, $Res Function(_LocalImage) _then) = __$LocalImageCopyWithImpl;
@override @useResult
$Res call({
 String path
});




}
/// @nodoc
class __$LocalImageCopyWithImpl<$Res>
    implements _$LocalImageCopyWith<$Res> {
  __$LocalImageCopyWithImpl(this._self, this._then);

  final _LocalImage _self;
  final $Res Function(_LocalImage) _then;

/// Create a copy of LocalImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(_LocalImage(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
