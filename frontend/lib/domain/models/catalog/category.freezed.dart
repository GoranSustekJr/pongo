// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpCategory {

 String get id; String get name; List<SpCategoryIcon> get categoryIcons;
/// Create a copy of SpCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpCategoryCopyWith<SpCategory> get copyWith => _$SpCategoryCopyWithImpl<SpCategory>(this as SpCategory, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.categoryIcons, _this.categoryIcons));
}


@override
int get hashCode {
  final _this = this as SpCategory;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.categoryIcons));
}

@override
String toString() {
  final _this = this as SpCategory;
  return 'SpCategory(id: ${_this.id}, name: ${_this.name}, categoryIcons: ${_this.categoryIcons})';
}


}

/// @nodoc
abstract mixin class $SpCategoryCopyWith<$Res>  {
  factory $SpCategoryCopyWith(SpCategory value, $Res Function(SpCategory) _then) = _$SpCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<SpCategoryIcon> categoryIcons
});




}
/// @nodoc
class _$SpCategoryCopyWithImpl<$Res>
    implements $SpCategoryCopyWith<$Res> {
  _$SpCategoryCopyWithImpl(this._self, this._then);

  final SpCategory _self;
  final $Res Function(SpCategory) _then;

/// Create a copy of SpCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryIcons = null,}) {
  return _then(SpCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryIcons: null == categoryIcons ? _self.categoryIcons : categoryIcons // ignore: cast_nullable_to_non_nullable
as List<SpCategoryIcon>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpCategory].
extension SpCategoryPatterns on SpCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpCategory value)  $default,){
final _that = this;
switch (_that) {
case _SpCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpCategory value)?  $default,){
final _that = this;
switch (_that) {
case _SpCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<SpCategoryIcon> categoryIcons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpCategory() when $default != null:
return $default(_that.id,_that.name,_that.categoryIcons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<SpCategoryIcon> categoryIcons)  $default,) {final _that = this;
switch (_that) {
case _SpCategory():
return $default(_that.id,_that.name,_that.categoryIcons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<SpCategoryIcon> categoryIcons)?  $default,) {final _that = this;
switch (_that) {
case _SpCategory() when $default != null:
return $default(_that.id,_that.name,_that.categoryIcons);case _:
  return null;

}
}

}

/// @nodoc


class _SpCategory implements SpCategory {
  const _SpCategory({required this.id, required this.name, required  List<SpCategoryIcon> categoryIcons}): _categoryIcons = categoryIcons;
  

@override final  String id;
@override final  String name;
 final  List<SpCategoryIcon> _categoryIcons;
@override List<SpCategoryIcon> get categoryIcons {
  if (_categoryIcons is EqualUnmodifiableListView) return _categoryIcons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIcons);
}


/// Create a copy of SpCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpCategoryCopyWith<_SpCategory> get copyWith => __$SpCategoryCopyWithImpl<_SpCategory>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.categoryIcons, _categoryIcons));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_categoryIcons));
}

@override
String toString() {
    return 'SpCategory(id: $id, name: $name, categoryIcons: $categoryIcons)';
}


}

/// @nodoc
abstract mixin class _$SpCategoryCopyWith<$Res> implements $SpCategoryCopyWith<$Res> {
  factory _$SpCategoryCopyWith(_SpCategory value, $Res Function(_SpCategory) _then) = __$SpCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<SpCategoryIcon> categoryIcons
});




}
/// @nodoc
class __$SpCategoryCopyWithImpl<$Res>
    implements _$SpCategoryCopyWith<$Res> {
  __$SpCategoryCopyWithImpl(this._self, this._then);

  final _SpCategory _self;
  final $Res Function(_SpCategory) _then;

/// Create a copy of SpCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryIcons = null,}) {
  return _then(_SpCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryIcons: null == categoryIcons ? _self._categoryIcons : categoryIcons // ignore: cast_nullable_to_non_nullable
as List<SpCategoryIcon>,
  ));
}


}

/// @nodoc
mixin _$SpCategoryIcon {

 String get url; int? get width; int? get height;
/// Create a copy of SpCategoryIcon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpCategoryIconCopyWith<SpCategoryIcon> get copyWith => _$SpCategoryIconCopyWithImpl<SpCategoryIcon>(this as SpCategoryIcon, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpCategoryIcon;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpCategoryIcon&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}


@override
int get hashCode {
  final _this = this as SpCategoryIcon;
  return Object.hash(runtimeType,_this.url,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as SpCategoryIcon;
  return 'SpCategoryIcon(url: ${_this.url}, width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $SpCategoryIconCopyWith<$Res>  {
  factory $SpCategoryIconCopyWith(SpCategoryIcon value, $Res Function(SpCategoryIcon) _then) = _$SpCategoryIconCopyWithImpl;
@useResult
$Res call({
 String url, int? width, int? height
});




}
/// @nodoc
class _$SpCategoryIconCopyWithImpl<$Res>
    implements $SpCategoryIconCopyWith<$Res> {
  _$SpCategoryIconCopyWithImpl(this._self, this._then);

  final SpCategoryIcon _self;
  final $Res Function(SpCategoryIcon) _then;

/// Create a copy of SpCategoryIcon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? width = freezed,Object? height = freezed,}) {
  return _then(SpCategoryIcon(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpCategoryIcon].
extension SpCategoryIconPatterns on SpCategoryIcon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpCategoryIcon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpCategoryIcon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpCategoryIcon value)  $default,){
final _that = this;
switch (_that) {
case _SpCategoryIcon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpCategoryIcon value)?  $default,){
final _that = this;
switch (_that) {
case _SpCategoryIcon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int? width,  int? height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpCategoryIcon() when $default != null:
return $default(_that.url,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int? width,  int? height)  $default,) {final _that = this;
switch (_that) {
case _SpCategoryIcon():
return $default(_that.url,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int? width,  int? height)?  $default,) {final _that = this;
switch (_that) {
case _SpCategoryIcon() when $default != null:
return $default(_that.url,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _SpCategoryIcon implements SpCategoryIcon {
  const _SpCategoryIcon({required this.url, this.width, this.height});
  

@override final  String url;
@override final  int? width;
@override final  int? height;

/// Create a copy of SpCategoryIcon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpCategoryIconCopyWith<_SpCategoryIcon> get copyWith => __$SpCategoryIconCopyWithImpl<_SpCategoryIcon>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpCategoryIcon&&(identical(other.url, url) || other.url == url)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,width,height);
}

@override
String toString() {
    return 'SpCategoryIcon(url: $url, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$SpCategoryIconCopyWith<$Res> implements $SpCategoryIconCopyWith<$Res> {
  factory _$SpCategoryIconCopyWith(_SpCategoryIcon value, $Res Function(_SpCategoryIcon) _then) = __$SpCategoryIconCopyWithImpl;
@override @useResult
$Res call({
 String url, int? width, int? height
});




}
/// @nodoc
class __$SpCategoryIconCopyWithImpl<$Res>
    implements _$SpCategoryIconCopyWith<$Res> {
  __$SpCategoryIconCopyWithImpl(this._self, this._then);

  final _SpCategoryIcon _self;
  final $Res Function(_SpCategoryIcon) _then;

/// Create a copy of SpCategoryIcon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? width = freezed,Object? height = freezed,}) {
  return _then(_SpCategoryIcon(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
