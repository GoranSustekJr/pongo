// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'online_playlist_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnlinePlaylistTrack {

 int get opid; String get stid; String get title; List<ArtistTrack> get artistTrack; AlbumTrack? get albumTrack; String? get image; int get orderNumber; bool get hidden;
/// Create a copy of OnlinePlaylistTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnlinePlaylistTrackCopyWith<OnlinePlaylistTrack> get copyWith => _$OnlinePlaylistTrackCopyWithImpl<OnlinePlaylistTrack>(this as OnlinePlaylistTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnlinePlaylistTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnlinePlaylistTrack&&(identical(other.opid, _this.opid) || other.opid == _this.opid)&&(identical(other.stid, _this.stid) || other.stid == _this.stid)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.artistTrack, _this.artistTrack)&&(identical(other.albumTrack, _this.albumTrack) || other.albumTrack == _this.albumTrack)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.orderNumber, _this.orderNumber) || other.orderNumber == _this.orderNumber)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden));
}


@override
int get hashCode {
  final _this = this as OnlinePlaylistTrack;
  return Object.hash(runtimeType,_this.opid,_this.stid,_this.title,const DeepCollectionEquality().hash(_this.artistTrack),_this.albumTrack,_this.image,_this.orderNumber,_this.hidden);
}

@override
String toString() {
  final _this = this as OnlinePlaylistTrack;
  return 'OnlinePlaylistTrack(opid: ${_this.opid}, stid: ${_this.stid}, title: ${_this.title}, artistTrack: ${_this.artistTrack}, albumTrack: ${_this.albumTrack}, image: ${_this.image}, orderNumber: ${_this.orderNumber}, hidden: ${_this.hidden})';
}


}

/// @nodoc
abstract mixin class $OnlinePlaylistTrackCopyWith<$Res>  {
  factory $OnlinePlaylistTrackCopyWith(OnlinePlaylistTrack value, $Res Function(OnlinePlaylistTrack) _then) = _$OnlinePlaylistTrackCopyWithImpl;
@useResult
$Res call({
 int opid, String stid, String title, List<ArtistTrack> artistTrack, AlbumTrack? albumTrack, String? image, int orderNumber, bool hidden
});


$AlbumTrackCopyWith<$Res>? get albumTrack;

}
/// @nodoc
class _$OnlinePlaylistTrackCopyWithImpl<$Res>
    implements $OnlinePlaylistTrackCopyWith<$Res> {
  _$OnlinePlaylistTrackCopyWithImpl(this._self, this._then);

  final OnlinePlaylistTrack _self;
  final $Res Function(OnlinePlaylistTrack) _then;

/// Create a copy of OnlinePlaylistTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opid = null,Object? stid = null,Object? title = null,Object? artistTrack = null,Object? albumTrack = freezed,Object? image = freezed,Object? orderNumber = null,Object? hidden = null,}) {
  return _then(OnlinePlaylistTrack(
opid: null == opid ? _self.opid : opid // ignore: cast_nullable_to_non_nullable
as int,stid: null == stid ? _self.stid : stid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistTrack: null == artistTrack ? _self.artistTrack : artistTrack // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,albumTrack: freezed == albumTrack ? _self.albumTrack : albumTrack // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of OnlinePlaylistTrack
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


/// Adds pattern-matching-related methods to [OnlinePlaylistTrack].
extension OnlinePlaylistTrackPatterns on OnlinePlaylistTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnlinePlaylistTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnlinePlaylistTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnlinePlaylistTrack value)  $default,){
final _that = this;
switch (_that) {
case _OnlinePlaylistTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnlinePlaylistTrack value)?  $default,){
final _that = this;
switch (_that) {
case _OnlinePlaylistTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int opid,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image,  int orderNumber,  bool hidden)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnlinePlaylistTrack() when $default != null:
return $default(_that.opid,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image,_that.orderNumber,_that.hidden);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int opid,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image,  int orderNumber,  bool hidden)  $default,) {final _that = this;
switch (_that) {
case _OnlinePlaylistTrack():
return $default(_that.opid,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image,_that.orderNumber,_that.hidden);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int opid,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image,  int orderNumber,  bool hidden)?  $default,) {final _that = this;
switch (_that) {
case _OnlinePlaylistTrack() when $default != null:
return $default(_that.opid,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image,_that.orderNumber,_that.hidden);case _:
  return null;

}
}

}

/// @nodoc


class _OnlinePlaylistTrack extends OnlinePlaylistTrack {
  const _OnlinePlaylistTrack({required this.opid, required this.stid, required this.title, required  List<ArtistTrack> artistTrack, required this.albumTrack, required this.image, required this.orderNumber, required this.hidden}): _artistTrack = artistTrack,super._();
  

@override final  int opid;
@override final  String stid;
@override final  String title;
 final  List<ArtistTrack> _artistTrack;
@override List<ArtistTrack> get artistTrack {
  if (_artistTrack is EqualUnmodifiableListView) return _artistTrack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artistTrack);
}

@override final  AlbumTrack? albumTrack;
@override final  String? image;
@override final  int orderNumber;
@override final  bool hidden;

/// Create a copy of OnlinePlaylistTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnlinePlaylistTrackCopyWith<_OnlinePlaylistTrack> get copyWith => __$OnlinePlaylistTrackCopyWithImpl<_OnlinePlaylistTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnlinePlaylistTrack&&(identical(other.opid, opid) || other.opid == opid)&&(identical(other.stid, stid) || other.stid == stid)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artistTrack, _artistTrack)&&(identical(other.albumTrack, albumTrack) || other.albumTrack == albumTrack)&&(identical(other.image, image) || other.image == image)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.hidden, hidden) || other.hidden == hidden));
}


@override
int get hashCode {
    return Object.hash(runtimeType,opid,stid,title,const DeepCollectionEquality().hash(_artistTrack),albumTrack,image,orderNumber,hidden);
}

@override
String toString() {
    return 'OnlinePlaylistTrack(opid: $opid, stid: $stid, title: $title, artistTrack: $artistTrack, albumTrack: $albumTrack, image: $image, orderNumber: $orderNumber, hidden: $hidden)';
}


}

/// @nodoc
abstract mixin class _$OnlinePlaylistTrackCopyWith<$Res> implements $OnlinePlaylistTrackCopyWith<$Res> {
  factory _$OnlinePlaylistTrackCopyWith(_OnlinePlaylistTrack value, $Res Function(_OnlinePlaylistTrack) _then) = __$OnlinePlaylistTrackCopyWithImpl;
@override @useResult
$Res call({
 int opid, String stid, String title, List<ArtistTrack> artistTrack, AlbumTrack? albumTrack, String? image, int orderNumber, bool hidden
});


@override $AlbumTrackCopyWith<$Res>? get albumTrack;

}
/// @nodoc
class __$OnlinePlaylistTrackCopyWithImpl<$Res>
    implements _$OnlinePlaylistTrackCopyWith<$Res> {
  __$OnlinePlaylistTrackCopyWithImpl(this._self, this._then);

  final _OnlinePlaylistTrack _self;
  final $Res Function(_OnlinePlaylistTrack) _then;

/// Create a copy of OnlinePlaylistTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opid = null,Object? stid = null,Object? title = null,Object? artistTrack = null,Object? albumTrack = freezed,Object? image = freezed,Object? orderNumber = null,Object? hidden = null,}) {
  return _then(_OnlinePlaylistTrack(
opid: null == opid ? _self.opid : opid // ignore: cast_nullable_to_non_nullable
as int,stid: null == stid ? _self.stid : stid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistTrack: null == artistTrack ? _self._artistTrack : artistTrack // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,albumTrack: freezed == albumTrack ? _self.albumTrack : albumTrack // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,orderNumber: null == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as int,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OnlinePlaylistTrack
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

// dart format on
