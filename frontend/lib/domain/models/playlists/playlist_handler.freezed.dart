// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_handler.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistHandler {

 PlaylistHandlerType get type; PlaylistHandlerFunction get function; List<PlaylistHandlerTrack>? get track;/// Track IDs that have to be downloaded before an offline playlist can
/// hold them.
 List<String> get toDownload;
/// Create a copy of PlaylistHandler
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistHandlerCopyWith<PlaylistHandler> get copyWith => _$PlaylistHandlerCopyWithImpl<PlaylistHandler>(this as PlaylistHandler, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistHandler;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistHandler&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.function, _this.function) || other.function == _this.function)&&const DeepCollectionEquality().equals(other.track, _this.track)&&const DeepCollectionEquality().equals(other.toDownload, _this.toDownload));
}


@override
int get hashCode {
  final _this = this as PlaylistHandler;
  return Object.hash(runtimeType,_this.type,_this.function,const DeepCollectionEquality().hash(_this.track),const DeepCollectionEquality().hash(_this.toDownload));
}

@override
String toString() {
  final _this = this as PlaylistHandler;
  return 'PlaylistHandler(type: ${_this.type}, function: ${_this.function}, track: ${_this.track}, toDownload: ${_this.toDownload})';
}


}

/// @nodoc
abstract mixin class $PlaylistHandlerCopyWith<$Res>  {
  factory $PlaylistHandlerCopyWith(PlaylistHandler value, $Res Function(PlaylistHandler) _then) = _$PlaylistHandlerCopyWithImpl;
@useResult
$Res call({
 PlaylistHandlerType type, PlaylistHandlerFunction function, List<PlaylistHandlerTrack>? track, List<String> toDownload
});




}
/// @nodoc
class _$PlaylistHandlerCopyWithImpl<$Res>
    implements $PlaylistHandlerCopyWith<$Res> {
  _$PlaylistHandlerCopyWithImpl(this._self, this._then);

  final PlaylistHandler _self;
  final $Res Function(PlaylistHandler) _then;

/// Create a copy of PlaylistHandler
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? function = null,Object? track = freezed,Object? toDownload = null,}) {
  return _then(PlaylistHandler(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerType,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerFunction,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as List<PlaylistHandlerTrack>?,toDownload: null == toDownload ? _self.toDownload : toDownload // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistHandler].
extension PlaylistHandlerPatterns on PlaylistHandler {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistHandler value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistHandler() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistHandler value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistHandler():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistHandler value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistHandler() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaylistHandlerType type,  PlaylistHandlerFunction function,  List<PlaylistHandlerTrack>? track,  List<String> toDownload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistHandler() when $default != null:
return $default(_that.type,_that.function,_that.track,_that.toDownload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaylistHandlerType type,  PlaylistHandlerFunction function,  List<PlaylistHandlerTrack>? track,  List<String> toDownload)  $default,) {final _that = this;
switch (_that) {
case _PlaylistHandler():
return $default(_that.type,_that.function,_that.track,_that.toDownload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaylistHandlerType type,  PlaylistHandlerFunction function,  List<PlaylistHandlerTrack>? track,  List<String> toDownload)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistHandler() when $default != null:
return $default(_that.type,_that.function,_that.track,_that.toDownload);case _:
  return null;

}
}

}

/// @nodoc


class _PlaylistHandler implements PlaylistHandler {
  const _PlaylistHandler({required this.type, required this.function, required  List<PlaylistHandlerTrack>? track,  List<String> toDownload = const <String>[]}): _track = track,_toDownload = toDownload;
  

@override final  PlaylistHandlerType type;
@override final  PlaylistHandlerFunction function;
 final  List<PlaylistHandlerTrack>? _track;
@override List<PlaylistHandlerTrack>? get track {
  final value = _track;
  if (value == null) return null;
  if (_track is EqualUnmodifiableListView) return _track;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Track IDs that have to be downloaded before an offline playlist can
/// hold them.
 final  List<String> _toDownload;
/// Track IDs that have to be downloaded before an offline playlist can
/// hold them.
@override@JsonKey() List<String> get toDownload {
  if (_toDownload is EqualUnmodifiableListView) return _toDownload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_toDownload);
}


/// Create a copy of PlaylistHandler
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistHandlerCopyWith<_PlaylistHandler> get copyWith => __$PlaylistHandlerCopyWithImpl<_PlaylistHandler>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistHandler&&(identical(other.type, type) || other.type == type)&&(identical(other.function, function) || other.function == function)&&const DeepCollectionEquality().equals(other.track, _track)&&const DeepCollectionEquality().equals(other.toDownload, _toDownload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,function,const DeepCollectionEquality().hash(_track),const DeepCollectionEquality().hash(_toDownload));
}

@override
String toString() {
    return 'PlaylistHandler(type: $type, function: $function, track: $track, toDownload: $toDownload)';
}


}

/// @nodoc
abstract mixin class _$PlaylistHandlerCopyWith<$Res> implements $PlaylistHandlerCopyWith<$Res> {
  factory _$PlaylistHandlerCopyWith(_PlaylistHandler value, $Res Function(_PlaylistHandler) _then) = __$PlaylistHandlerCopyWithImpl;
@override @useResult
$Res call({
 PlaylistHandlerType type, PlaylistHandlerFunction function, List<PlaylistHandlerTrack>? track, List<String> toDownload
});




}
/// @nodoc
class __$PlaylistHandlerCopyWithImpl<$Res>
    implements _$PlaylistHandlerCopyWith<$Res> {
  __$PlaylistHandlerCopyWithImpl(this._self, this._then);

  final _PlaylistHandler _self;
  final $Res Function(_PlaylistHandler) _then;

/// Create a copy of PlaylistHandler
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? function = null,Object? track = freezed,Object? toDownload = null,}) {
  return _then(_PlaylistHandler(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerType,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerFunction,track: freezed == track ? _self._track : track // ignore: cast_nullable_to_non_nullable
as List<PlaylistHandlerTrack>?,toDownload: null == toDownload ? _self._toDownload : toDownload // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$PlaylistHandlerTrack {

 String get id; String get name; List<ArtistTrack> get artist; String get cover; PlaylistHandlerCoverType get playlistHandlerCoverType;
/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistHandlerTrackCopyWith<PlaylistHandlerTrack> get copyWith => _$PlaylistHandlerTrackCopyWithImpl<PlaylistHandlerTrack>(this as PlaylistHandlerTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistHandlerTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistHandlerTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.artist, _this.artist)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.playlistHandlerCoverType, _this.playlistHandlerCoverType) || other.playlistHandlerCoverType == _this.playlistHandlerCoverType));
}


@override
int get hashCode {
  final _this = this as PlaylistHandlerTrack;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.artist),_this.cover,_this.playlistHandlerCoverType);
}

@override
String toString() {
  final _this = this as PlaylistHandlerTrack;
  return 'PlaylistHandlerTrack(id: ${_this.id}, name: ${_this.name}, artist: ${_this.artist}, cover: ${_this.cover}, playlistHandlerCoverType: ${_this.playlistHandlerCoverType})';
}


}

/// @nodoc
abstract mixin class $PlaylistHandlerTrackCopyWith<$Res>  {
  factory $PlaylistHandlerTrackCopyWith(PlaylistHandlerTrack value, $Res Function(PlaylistHandlerTrack) _then) = _$PlaylistHandlerTrackCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<ArtistTrack> artist, String cover, PlaylistHandlerCoverType playlistHandlerCoverType
});




}
/// @nodoc
class _$PlaylistHandlerTrackCopyWithImpl<$Res>
    implements $PlaylistHandlerTrackCopyWith<$Res> {
  _$PlaylistHandlerTrackCopyWithImpl(this._self, this._then);

  final PlaylistHandlerTrack _self;
  final $Res Function(PlaylistHandlerTrack) _then;

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artist = null,Object? cover = null,Object? playlistHandlerCoverType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,playlistHandlerCoverType: null == playlistHandlerCoverType ? _self.playlistHandlerCoverType : playlistHandlerCoverType // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerCoverType,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistHandlerTrack].
extension PlaylistHandlerTrackPatterns on PlaylistHandlerTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistHandlerOnlineTrack value)?  online,TResult Function( PlaylistHandlerOfflineTrack value)?  offline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack() when online != null:
return online(_that);case PlaylistHandlerOfflineTrack() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistHandlerOnlineTrack value)  online,required TResult Function( PlaylistHandlerOfflineTrack value)  offline,}){
final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack():
return online(_that);case PlaylistHandlerOfflineTrack():
return offline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistHandlerOnlineTrack value)?  online,TResult? Function( PlaylistHandlerOfflineTrack value)?  offline,}){
final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack() when online != null:
return online(_that);case PlaylistHandlerOfflineTrack() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  AlbumTrack? albumTrack,  PlaylistHandlerCoverType playlistHandlerCoverType)?  online,TResult Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  PlaylistHandlerCoverType playlistHandlerCoverType,  String filePath)?  offline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack() when online != null:
return online(_that.id,_that.name,_that.artist,_that.cover,_that.albumTrack,_that.playlistHandlerCoverType);case PlaylistHandlerOfflineTrack() when offline != null:
return offline(_that.id,_that.name,_that.artist,_that.cover,_that.playlistHandlerCoverType,_that.filePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  AlbumTrack? albumTrack,  PlaylistHandlerCoverType playlistHandlerCoverType)  online,required TResult Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  PlaylistHandlerCoverType playlistHandlerCoverType,  String filePath)  offline,}) {final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack():
return online(_that.id,_that.name,_that.artist,_that.cover,_that.albumTrack,_that.playlistHandlerCoverType);case PlaylistHandlerOfflineTrack():
return offline(_that.id,_that.name,_that.artist,_that.cover,_that.playlistHandlerCoverType,_that.filePath);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  AlbumTrack? albumTrack,  PlaylistHandlerCoverType playlistHandlerCoverType)?  online,TResult? Function( String id,  String name,  List<ArtistTrack> artist,  String cover,  PlaylistHandlerCoverType playlistHandlerCoverType,  String filePath)?  offline,}) {final _that = this;
switch (_that) {
case PlaylistHandlerOnlineTrack() when online != null:
return online(_that.id,_that.name,_that.artist,_that.cover,_that.albumTrack,_that.playlistHandlerCoverType);case PlaylistHandlerOfflineTrack() when offline != null:
return offline(_that.id,_that.name,_that.artist,_that.cover,_that.playlistHandlerCoverType,_that.filePath);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistHandlerOnlineTrack implements PlaylistHandlerTrack {
  const PlaylistHandlerOnlineTrack({required this.id, required this.name, required  List<ArtistTrack> artist, required this.cover, required this.albumTrack, required this.playlistHandlerCoverType}): _artist = artist;
  

@override final  String id;
@override final  String name;
 final  List<ArtistTrack> _artist;
@override List<ArtistTrack> get artist {
  if (_artist is EqualUnmodifiableListView) return _artist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artist);
}

@override final  String cover;
 final  AlbumTrack? albumTrack;
@override final  PlaylistHandlerCoverType playlistHandlerCoverType;

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistHandlerOnlineTrackCopyWith<PlaylistHandlerOnlineTrack> get copyWith => _$PlaylistHandlerOnlineTrackCopyWithImpl<PlaylistHandlerOnlineTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistHandlerOnlineTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.artist, _artist)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.albumTrack, albumTrack) || other.albumTrack == albumTrack)&&(identical(other.playlistHandlerCoverType, playlistHandlerCoverType) || other.playlistHandlerCoverType == playlistHandlerCoverType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_artist),cover,albumTrack,playlistHandlerCoverType);
}

@override
String toString() {
    return 'PlaylistHandlerTrack.online(id: $id, name: $name, artist: $artist, cover: $cover, albumTrack: $albumTrack, playlistHandlerCoverType: $playlistHandlerCoverType)';
}


}

/// @nodoc
abstract mixin class $PlaylistHandlerOnlineTrackCopyWith<$Res> implements $PlaylistHandlerTrackCopyWith<$Res> {
  factory $PlaylistHandlerOnlineTrackCopyWith(PlaylistHandlerOnlineTrack value, $Res Function(PlaylistHandlerOnlineTrack) _then) = _$PlaylistHandlerOnlineTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<ArtistTrack> artist, String cover, AlbumTrack? albumTrack, PlaylistHandlerCoverType playlistHandlerCoverType
});


$AlbumTrackCopyWith<$Res>? get albumTrack;

}
/// @nodoc
class _$PlaylistHandlerOnlineTrackCopyWithImpl<$Res>
    implements $PlaylistHandlerOnlineTrackCopyWith<$Res> {
  _$PlaylistHandlerOnlineTrackCopyWithImpl(this._self, this._then);

  final PlaylistHandlerOnlineTrack _self;
  final $Res Function(PlaylistHandlerOnlineTrack) _then;

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artist = null,Object? cover = null,Object? albumTrack = freezed,Object? playlistHandlerCoverType = null,}) {
  return _then(PlaylistHandlerOnlineTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self._artist : artist // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,albumTrack: freezed == albumTrack ? _self.albumTrack : albumTrack // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,playlistHandlerCoverType: null == playlistHandlerCoverType ? _self.playlistHandlerCoverType : playlistHandlerCoverType // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerCoverType,
  ));
}

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumTrackCopyWith<$Res>? get albumTrack {
    if (_self.albumTrack == null) {
    return null;
  }

  return $AlbumTrackCopyWith<$Res>(_self.albumTrack!, (value) {
    return _then(_self.copyWith(albumTrack: value));
  });
}
}

/// @nodoc


class PlaylistHandlerOfflineTrack implements PlaylistHandlerTrack {
  const PlaylistHandlerOfflineTrack({required this.id, required this.name, required  List<ArtistTrack> artist, required this.cover, required this.playlistHandlerCoverType, required this.filePath}): _artist = artist;
  

@override final  String id;
@override final  String name;
 final  List<ArtistTrack> _artist;
@override List<ArtistTrack> get artist {
  if (_artist is EqualUnmodifiableListView) return _artist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artist);
}

@override final  String cover;
@override final  PlaylistHandlerCoverType playlistHandlerCoverType;
 final  String filePath;

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistHandlerOfflineTrackCopyWith<PlaylistHandlerOfflineTrack> get copyWith => _$PlaylistHandlerOfflineTrackCopyWithImpl<PlaylistHandlerOfflineTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistHandlerOfflineTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.artist, _artist)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.playlistHandlerCoverType, playlistHandlerCoverType) || other.playlistHandlerCoverType == playlistHandlerCoverType)&&(identical(other.filePath, filePath) || other.filePath == filePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_artist),cover,playlistHandlerCoverType,filePath);
}

@override
String toString() {
    return 'PlaylistHandlerTrack.offline(id: $id, name: $name, artist: $artist, cover: $cover, playlistHandlerCoverType: $playlistHandlerCoverType, filePath: $filePath)';
}


}

/// @nodoc
abstract mixin class $PlaylistHandlerOfflineTrackCopyWith<$Res> implements $PlaylistHandlerTrackCopyWith<$Res> {
  factory $PlaylistHandlerOfflineTrackCopyWith(PlaylistHandlerOfflineTrack value, $Res Function(PlaylistHandlerOfflineTrack) _then) = _$PlaylistHandlerOfflineTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<ArtistTrack> artist, String cover, PlaylistHandlerCoverType playlistHandlerCoverType, String filePath
});




}
/// @nodoc
class _$PlaylistHandlerOfflineTrackCopyWithImpl<$Res>
    implements $PlaylistHandlerOfflineTrackCopyWith<$Res> {
  _$PlaylistHandlerOfflineTrackCopyWithImpl(this._self, this._then);

  final PlaylistHandlerOfflineTrack _self;
  final $Res Function(PlaylistHandlerOfflineTrack) _then;

/// Create a copy of PlaylistHandlerTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artist = null,Object? cover = null,Object? playlistHandlerCoverType = null,Object? filePath = null,}) {
  return _then(PlaylistHandlerOfflineTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self._artist : artist // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,playlistHandlerCoverType: null == playlistHandlerCoverType ? _self.playlistHandlerCoverType : playlistHandlerCoverType // ignore: cast_nullable_to_non_nullable
as PlaylistHandlerCoverType,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
