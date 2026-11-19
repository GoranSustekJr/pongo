// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favourite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Favourite {

 int get id; String get stid; String get title; List<ArtistTrack> get artistTrack; AlbumTrack? get albumTrack; String? get image;
/// Create a copy of Favourite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavouriteCopyWith<Favourite> get copyWith => _$FavouriteCopyWithImpl<Favourite>(this as Favourite, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Favourite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Favourite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stid, _this.stid) || other.stid == _this.stid)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.artistTrack, _this.artistTrack)&&(identical(other.albumTrack, _this.albumTrack) || other.albumTrack == _this.albumTrack)&&(identical(other.image, _this.image) || other.image == _this.image));
}


@override
int get hashCode {
  final _this = this as Favourite;
  return Object.hash(runtimeType,_this.id,_this.stid,_this.title,const DeepCollectionEquality().hash(_this.artistTrack),_this.albumTrack,_this.image);
}

@override
String toString() {
  final _this = this as Favourite;
  return 'Favourite(id: ${_this.id}, stid: ${_this.stid}, title: ${_this.title}, artistTrack: ${_this.artistTrack}, albumTrack: ${_this.albumTrack}, image: ${_this.image})';
}


}

/// @nodoc
abstract mixin class $FavouriteCopyWith<$Res>  {
  factory $FavouriteCopyWith(Favourite value, $Res Function(Favourite) _then) = _$FavouriteCopyWithImpl;
@useResult
$Res call({
 int id, String stid, String title, List<ArtistTrack> artistTrack, AlbumTrack? albumTrack, String? image
});


$AlbumTrackCopyWith<$Res>? get albumTrack;

}
/// @nodoc
class _$FavouriteCopyWithImpl<$Res>
    implements $FavouriteCopyWith<$Res> {
  _$FavouriteCopyWithImpl(this._self, this._then);

  final Favourite _self;
  final $Res Function(Favourite) _then;

/// Create a copy of Favourite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stid = null,Object? title = null,Object? artistTrack = null,Object? albumTrack = freezed,Object? image = freezed,}) {
  return _then(Favourite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stid: null == stid ? _self.stid : stid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistTrack: null == artistTrack ? _self.artistTrack : artistTrack // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,albumTrack: freezed == albumTrack ? _self.albumTrack : albumTrack // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Favourite
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


/// Adds pattern-matching-related methods to [Favourite].
extension FavouritePatterns on Favourite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Favourite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Favourite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Favourite value)  $default,){
final _that = this;
switch (_that) {
case _Favourite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Favourite value)?  $default,){
final _that = this;
switch (_that) {
case _Favourite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Favourite() when $default != null:
return $default(_that.id,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image)  $default,) {final _that = this;
switch (_that) {
case _Favourite():
return $default(_that.id,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String stid,  String title,  List<ArtistTrack> artistTrack,  AlbumTrack? albumTrack,  String? image)?  $default,) {final _that = this;
switch (_that) {
case _Favourite() when $default != null:
return $default(_that.id,_that.stid,_that.title,_that.artistTrack,_that.albumTrack,_that.image);case _:
  return null;

}
}

}

/// @nodoc


class _Favourite extends Favourite {
  const _Favourite({required this.id, required this.stid, required this.title, required  List<ArtistTrack> artistTrack, required this.albumTrack, required this.image}): _artistTrack = artistTrack,super._();
  

@override final  int id;
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

/// Create a copy of Favourite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavouriteCopyWith<_Favourite> get copyWith => __$FavouriteCopyWithImpl<_Favourite>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Favourite&&(identical(other.id, id) || other.id == id)&&(identical(other.stid, stid) || other.stid == stid)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artistTrack, _artistTrack)&&(identical(other.albumTrack, albumTrack) || other.albumTrack == albumTrack)&&(identical(other.image, image) || other.image == image));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stid,title,const DeepCollectionEquality().hash(_artistTrack),albumTrack,image);
}

@override
String toString() {
    return 'Favourite(id: $id, stid: $stid, title: $title, artistTrack: $artistTrack, albumTrack: $albumTrack, image: $image)';
}


}

/// @nodoc
abstract mixin class _$FavouriteCopyWith<$Res> implements $FavouriteCopyWith<$Res> {
  factory _$FavouriteCopyWith(_Favourite value, $Res Function(_Favourite) _then) = __$FavouriteCopyWithImpl;
@override @useResult
$Res call({
 int id, String stid, String title, List<ArtistTrack> artistTrack, AlbumTrack? albumTrack, String? image
});


@override $AlbumTrackCopyWith<$Res>? get albumTrack;

}
/// @nodoc
class __$FavouriteCopyWithImpl<$Res>
    implements _$FavouriteCopyWith<$Res> {
  __$FavouriteCopyWithImpl(this._self, this._then);

  final _Favourite _self;
  final $Res Function(_Favourite) _then;

/// Create a copy of Favourite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stid = null,Object? title = null,Object? artistTrack = null,Object? albumTrack = freezed,Object? image = freezed,}) {
  return _then(_Favourite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stid: null == stid ? _self.stid : stid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistTrack: null == artistTrack ? _self._artistTrack : artistTrack // ignore: cast_nullable_to_non_nullable
as List<ArtistTrack>,albumTrack: freezed == albumTrack ? _self.albumTrack : albumTrack // ignore: cast_nullable_to_non_nullable
as AlbumTrack?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Favourite
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
