// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserPlaylist {

/// The playlist's ID in its table.
 int get id; String get title;/// The cover image bytes, if the user set one.
 Uint8List? get cover;
/// Create a copy of UserPlaylist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPlaylistCopyWith<UserPlaylist> get copyWith => _$UserPlaylistCopyWithImpl<UserPlaylist>(this as UserPlaylist, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserPlaylist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPlaylist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.cover, _this.cover));
}


@override
int get hashCode {
  final _this = this as UserPlaylist;
  return Object.hash(runtimeType,_this.id,_this.title,const DeepCollectionEquality().hash(_this.cover));
}

@override
String toString() {
  final _this = this as UserPlaylist;
  return 'UserPlaylist(id: ${_this.id}, title: ${_this.title}, cover: ${_this.cover})';
}


}

/// @nodoc
abstract mixin class $UserPlaylistCopyWith<$Res>  {
  factory $UserPlaylistCopyWith(UserPlaylist value, $Res Function(UserPlaylist) _then) = _$UserPlaylistCopyWithImpl;
@useResult
$Res call({
 int id, String title, Uint8List? cover
});




}
/// @nodoc
class _$UserPlaylistCopyWithImpl<$Res>
    implements $UserPlaylistCopyWith<$Res> {
  _$UserPlaylistCopyWithImpl(this._self, this._then);

  final UserPlaylist _self;
  final $Res Function(UserPlaylist) _then;

/// Create a copy of UserPlaylist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? cover = freezed,}) {
  return _then(UserPlaylist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPlaylist].
extension UserPlaylistPatterns on UserPlaylist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPlaylist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPlaylist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPlaylist value)  $default,){
final _that = this;
switch (_that) {
case _UserPlaylist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPlaylist value)?  $default,){
final _that = this;
switch (_that) {
case _UserPlaylist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  Uint8List? cover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPlaylist() when $default != null:
return $default(_that.id,_that.title,_that.cover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  Uint8List? cover)  $default,) {final _that = this;
switch (_that) {
case _UserPlaylist():
return $default(_that.id,_that.title,_that.cover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  Uint8List? cover)?  $default,) {final _that = this;
switch (_that) {
case _UserPlaylist() when $default != null:
return $default(_that.id,_that.title,_that.cover);case _:
  return null;

}
}

}

/// @nodoc


class _UserPlaylist implements UserPlaylist {
  const _UserPlaylist({required this.id, required this.title, this.cover});
  

/// The playlist's ID in its table.
@override final  int id;
@override final  String title;
/// The cover image bytes, if the user set one.
@override final  Uint8List? cover;

/// Create a copy of UserPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPlaylistCopyWith<_UserPlaylist> get copyWith => __$UserPlaylistCopyWithImpl<_UserPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPlaylist&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.cover, cover));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(cover));
}

@override
String toString() {
    return 'UserPlaylist(id: $id, title: $title, cover: $cover)';
}


}

/// @nodoc
abstract mixin class _$UserPlaylistCopyWith<$Res> implements $UserPlaylistCopyWith<$Res> {
  factory _$UserPlaylistCopyWith(_UserPlaylist value, $Res Function(_UserPlaylist) _then) = __$UserPlaylistCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, Uint8List? cover
});




}
/// @nodoc
class __$UserPlaylistCopyWithImpl<$Res>
    implements _$UserPlaylistCopyWith<$Res> {
  __$UserPlaylistCopyWithImpl(this._self, this._then);

  final _UserPlaylist _self;
  final $Res Function(_UserPlaylist) _then;

/// Create a copy of UserPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? cover = freezed,}) {
  return _then(_UserPlaylist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

/// @nodoc
mixin _$DownloadedTrack {

 Track get track;/// The track's length in milliseconds.
 int get durationMilliseconds;/// The row ID, which grows with each download.
 int get rowId;/// Whether the track is hidden, when it's part of a playlist.
 bool get hidden;
/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadedTrackCopyWith<DownloadedTrack> get copyWith => _$DownloadedTrackCopyWithImpl<DownloadedTrack>(this as DownloadedTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DownloadedTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedTrack&&(identical(other.track, _this.track) || other.track == _this.track)&&(identical(other.durationMilliseconds, _this.durationMilliseconds) || other.durationMilliseconds == _this.durationMilliseconds)&&(identical(other.rowId, _this.rowId) || other.rowId == _this.rowId)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden));
}


@override
int get hashCode {
  final _this = this as DownloadedTrack;
  return Object.hash(runtimeType,_this.track,_this.durationMilliseconds,_this.rowId,_this.hidden);
}

@override
String toString() {
  final _this = this as DownloadedTrack;
  return 'DownloadedTrack(track: ${_this.track}, durationMilliseconds: ${_this.durationMilliseconds}, rowId: ${_this.rowId}, hidden: ${_this.hidden})';
}


}

/// @nodoc
abstract mixin class $DownloadedTrackCopyWith<$Res>  {
  factory $DownloadedTrackCopyWith(DownloadedTrack value, $Res Function(DownloadedTrack) _then) = _$DownloadedTrackCopyWithImpl;
@useResult
$Res call({
 Track track, int durationMilliseconds, int rowId, bool hidden
});


$TrackCopyWith<$Res> get track;

}
/// @nodoc
class _$DownloadedTrackCopyWithImpl<$Res>
    implements $DownloadedTrackCopyWith<$Res> {
  _$DownloadedTrackCopyWithImpl(this._self, this._then);

  final DownloadedTrack _self;
  final $Res Function(DownloadedTrack) _then;

/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? track = null,Object? durationMilliseconds = null,Object? rowId = null,Object? hidden = null,}) {
  return _then(DownloadedTrack(
track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,durationMilliseconds: null == durationMilliseconds ? _self.durationMilliseconds : durationMilliseconds // ignore: cast_nullable_to_non_nullable
as int,rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}


/// Adds pattern-matching-related methods to [DownloadedTrack].
extension DownloadedTrackPatterns on DownloadedTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedTrack value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedTrack value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Track track,  int durationMilliseconds,  int rowId,  bool hidden)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedTrack() when $default != null:
return $default(_that.track,_that.durationMilliseconds,_that.rowId,_that.hidden);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Track track,  int durationMilliseconds,  int rowId,  bool hidden)  $default,) {final _that = this;
switch (_that) {
case _DownloadedTrack():
return $default(_that.track,_that.durationMilliseconds,_that.rowId,_that.hidden);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Track track,  int durationMilliseconds,  int rowId,  bool hidden)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedTrack() when $default != null:
return $default(_that.track,_that.durationMilliseconds,_that.rowId,_that.hidden);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadedTrack implements DownloadedTrack {
  const _DownloadedTrack({required this.track, required this.durationMilliseconds, required this.rowId, this.hidden = false});
  

@override final  Track track;
/// The track's length in milliseconds.
@override final  int durationMilliseconds;
/// The row ID, which grows with each download.
@override final  int rowId;
/// Whether the track is hidden, when it's part of a playlist.
@override@JsonKey() final  bool hidden;

/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadedTrackCopyWith<_DownloadedTrack> get copyWith => __$DownloadedTrackCopyWithImpl<_DownloadedTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedTrack&&(identical(other.track, track) || other.track == track)&&(identical(other.durationMilliseconds, durationMilliseconds) || other.durationMilliseconds == durationMilliseconds)&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.hidden, hidden) || other.hidden == hidden));
}


@override
int get hashCode {
    return Object.hash(runtimeType,track,durationMilliseconds,rowId,hidden);
}

@override
String toString() {
    return 'DownloadedTrack(track: $track, durationMilliseconds: $durationMilliseconds, rowId: $rowId, hidden: $hidden)';
}


}

/// @nodoc
abstract mixin class _$DownloadedTrackCopyWith<$Res> implements $DownloadedTrackCopyWith<$Res> {
  factory _$DownloadedTrackCopyWith(_DownloadedTrack value, $Res Function(_DownloadedTrack) _then) = __$DownloadedTrackCopyWithImpl;
@override @useResult
$Res call({
 Track track, int durationMilliseconds, int rowId, bool hidden
});


@override $TrackCopyWith<$Res> get track;

}
/// @nodoc
class __$DownloadedTrackCopyWithImpl<$Res>
    implements _$DownloadedTrackCopyWith<$Res> {
  __$DownloadedTrackCopyWithImpl(this._self, this._then);

  final _DownloadedTrack _self;
  final $Res Function(_DownloadedTrack) _then;

/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? track = null,Object? durationMilliseconds = null,Object? rowId = null,Object? hidden = null,}) {
  return _then(_DownloadedTrack(
track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,durationMilliseconds: null == durationMilliseconds ? _self.durationMilliseconds : durationMilliseconds // ignore: cast_nullable_to_non_nullable
as int,rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DownloadedTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}

// dart format on
