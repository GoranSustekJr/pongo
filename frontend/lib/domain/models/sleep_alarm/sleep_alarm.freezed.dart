// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_alarm.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SleepAlarm {

 int get id;/// Whether the music fades out.
 bool get sleep;/// Minutes the fade out takes.
 int get sleepDuration; bool get sleepLinear;/// Whether the music fades back in at [wakeTime].
 bool get alarmClock;/// Minutes after midnight the fade in ends. Defaults to 7:30 am.
 int get wakeTime;/// Minutes the fade in takes.
 int get beforeEndTimeMin; bool get alarmClockLinear;
/// Create a copy of SleepAlarm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SleepAlarmCopyWith<SleepAlarm> get copyWith => _$SleepAlarmCopyWithImpl<SleepAlarm>(this as SleepAlarm, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SleepAlarm;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SleepAlarm&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sleep, _this.sleep) || other.sleep == _this.sleep)&&(identical(other.sleepDuration, _this.sleepDuration) || other.sleepDuration == _this.sleepDuration)&&(identical(other.sleepLinear, _this.sleepLinear) || other.sleepLinear == _this.sleepLinear)&&(identical(other.alarmClock, _this.alarmClock) || other.alarmClock == _this.alarmClock)&&(identical(other.wakeTime, _this.wakeTime) || other.wakeTime == _this.wakeTime)&&(identical(other.beforeEndTimeMin, _this.beforeEndTimeMin) || other.beforeEndTimeMin == _this.beforeEndTimeMin)&&(identical(other.alarmClockLinear, _this.alarmClockLinear) || other.alarmClockLinear == _this.alarmClockLinear));
}


@override
int get hashCode {
  final _this = this as SleepAlarm;
  return Object.hash(runtimeType,_this.id,_this.sleep,_this.sleepDuration,_this.sleepLinear,_this.alarmClock,_this.wakeTime,_this.beforeEndTimeMin,_this.alarmClockLinear);
}

@override
String toString() {
  final _this = this as SleepAlarm;
  return 'SleepAlarm(id: ${_this.id}, sleep: ${_this.sleep}, sleepDuration: ${_this.sleepDuration}, sleepLinear: ${_this.sleepLinear}, alarmClock: ${_this.alarmClock}, wakeTime: ${_this.wakeTime}, beforeEndTimeMin: ${_this.beforeEndTimeMin}, alarmClockLinear: ${_this.alarmClockLinear})';
}


}

/// @nodoc
abstract mixin class $SleepAlarmCopyWith<$Res>  {
  factory $SleepAlarmCopyWith(SleepAlarm value, $Res Function(SleepAlarm) _then) = _$SleepAlarmCopyWithImpl;
@useResult
$Res call({
 int id, bool sleep, int sleepDuration, bool sleepLinear, bool alarmClock, int wakeTime, int beforeEndTimeMin, bool alarmClockLinear
});




}
/// @nodoc
class _$SleepAlarmCopyWithImpl<$Res>
    implements $SleepAlarmCopyWith<$Res> {
  _$SleepAlarmCopyWithImpl(this._self, this._then);

  final SleepAlarm _self;
  final $Res Function(SleepAlarm) _then;

/// Create a copy of SleepAlarm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sleep = null,Object? sleepDuration = null,Object? sleepLinear = null,Object? alarmClock = null,Object? wakeTime = null,Object? beforeEndTimeMin = null,Object? alarmClockLinear = null,}) {
  return _then(SleepAlarm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sleep: null == sleep ? _self.sleep : sleep // ignore: cast_nullable_to_non_nullable
as bool,sleepDuration: null == sleepDuration ? _self.sleepDuration : sleepDuration // ignore: cast_nullable_to_non_nullable
as int,sleepLinear: null == sleepLinear ? _self.sleepLinear : sleepLinear // ignore: cast_nullable_to_non_nullable
as bool,alarmClock: null == alarmClock ? _self.alarmClock : alarmClock // ignore: cast_nullable_to_non_nullable
as bool,wakeTime: null == wakeTime ? _self.wakeTime : wakeTime // ignore: cast_nullable_to_non_nullable
as int,beforeEndTimeMin: null == beforeEndTimeMin ? _self.beforeEndTimeMin : beforeEndTimeMin // ignore: cast_nullable_to_non_nullable
as int,alarmClockLinear: null == alarmClockLinear ? _self.alarmClockLinear : alarmClockLinear // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SleepAlarm].
extension SleepAlarmPatterns on SleepAlarm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SleepAlarm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SleepAlarm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SleepAlarm value)  $default,){
final _that = this;
switch (_that) {
case _SleepAlarm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SleepAlarm value)?  $default,){
final _that = this;
switch (_that) {
case _SleepAlarm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  bool sleep,  int sleepDuration,  bool sleepLinear,  bool alarmClock,  int wakeTime,  int beforeEndTimeMin,  bool alarmClockLinear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SleepAlarm() when $default != null:
return $default(_that.id,_that.sleep,_that.sleepDuration,_that.sleepLinear,_that.alarmClock,_that.wakeTime,_that.beforeEndTimeMin,_that.alarmClockLinear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  bool sleep,  int sleepDuration,  bool sleepLinear,  bool alarmClock,  int wakeTime,  int beforeEndTimeMin,  bool alarmClockLinear)  $default,) {final _that = this;
switch (_that) {
case _SleepAlarm():
return $default(_that.id,_that.sleep,_that.sleepDuration,_that.sleepLinear,_that.alarmClock,_that.wakeTime,_that.beforeEndTimeMin,_that.alarmClockLinear);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  bool sleep,  int sleepDuration,  bool sleepLinear,  bool alarmClock,  int wakeTime,  int beforeEndTimeMin,  bool alarmClockLinear)?  $default,) {final _that = this;
switch (_that) {
case _SleepAlarm() when $default != null:
return $default(_that.id,_that.sleep,_that.sleepDuration,_that.sleepLinear,_that.alarmClock,_that.wakeTime,_that.beforeEndTimeMin,_that.alarmClockLinear);case _:
  return null;

}
}

}

/// @nodoc


class _SleepAlarm implements SleepAlarm {
  const _SleepAlarm({required this.id, this.sleep = true, this.sleepDuration = 30, this.sleepLinear = true, this.alarmClock = false, this.wakeTime = 450, this.beforeEndTimeMin = 30, this.alarmClockLinear = true});
  

@override final  int id;
/// Whether the music fades out.
@override@JsonKey() final  bool sleep;
/// Minutes the fade out takes.
@override@JsonKey() final  int sleepDuration;
@override@JsonKey() final  bool sleepLinear;
/// Whether the music fades back in at [wakeTime].
@override@JsonKey() final  bool alarmClock;
/// Minutes after midnight the fade in ends. Defaults to 7:30 am.
@override@JsonKey() final  int wakeTime;
/// Minutes the fade in takes.
@override@JsonKey() final  int beforeEndTimeMin;
@override@JsonKey() final  bool alarmClockLinear;

/// Create a copy of SleepAlarm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SleepAlarmCopyWith<_SleepAlarm> get copyWith => __$SleepAlarmCopyWithImpl<_SleepAlarm>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SleepAlarm&&(identical(other.id, id) || other.id == id)&&(identical(other.sleep, sleep) || other.sleep == sleep)&&(identical(other.sleepDuration, sleepDuration) || other.sleepDuration == sleepDuration)&&(identical(other.sleepLinear, sleepLinear) || other.sleepLinear == sleepLinear)&&(identical(other.alarmClock, alarmClock) || other.alarmClock == alarmClock)&&(identical(other.wakeTime, wakeTime) || other.wakeTime == wakeTime)&&(identical(other.beforeEndTimeMin, beforeEndTimeMin) || other.beforeEndTimeMin == beforeEndTimeMin)&&(identical(other.alarmClockLinear, alarmClockLinear) || other.alarmClockLinear == alarmClockLinear));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,sleep,sleepDuration,sleepLinear,alarmClock,wakeTime,beforeEndTimeMin,alarmClockLinear);
}

@override
String toString() {
    return 'SleepAlarm(id: $id, sleep: $sleep, sleepDuration: $sleepDuration, sleepLinear: $sleepLinear, alarmClock: $alarmClock, wakeTime: $wakeTime, beforeEndTimeMin: $beforeEndTimeMin, alarmClockLinear: $alarmClockLinear)';
}


}

/// @nodoc
abstract mixin class _$SleepAlarmCopyWith<$Res> implements $SleepAlarmCopyWith<$Res> {
  factory _$SleepAlarmCopyWith(_SleepAlarm value, $Res Function(_SleepAlarm) _then) = __$SleepAlarmCopyWithImpl;
@override @useResult
$Res call({
 int id, bool sleep, int sleepDuration, bool sleepLinear, bool alarmClock, int wakeTime, int beforeEndTimeMin, bool alarmClockLinear
});




}
/// @nodoc
class __$SleepAlarmCopyWithImpl<$Res>
    implements _$SleepAlarmCopyWith<$Res> {
  __$SleepAlarmCopyWithImpl(this._self, this._then);

  final _SleepAlarm _self;
  final $Res Function(_SleepAlarm) _then;

/// Create a copy of SleepAlarm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sleep = null,Object? sleepDuration = null,Object? sleepLinear = null,Object? alarmClock = null,Object? wakeTime = null,Object? beforeEndTimeMin = null,Object? alarmClockLinear = null,}) {
  return _then(_SleepAlarm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sleep: null == sleep ? _self.sleep : sleep // ignore: cast_nullable_to_non_nullable
as bool,sleepDuration: null == sleepDuration ? _self.sleepDuration : sleepDuration // ignore: cast_nullable_to_non_nullable
as int,sleepLinear: null == sleepLinear ? _self.sleepLinear : sleepLinear // ignore: cast_nullable_to_non_nullable
as bool,alarmClock: null == alarmClock ? _self.alarmClock : alarmClock // ignore: cast_nullable_to_non_nullable
as bool,wakeTime: null == wakeTime ? _self.wakeTime : wakeTime // ignore: cast_nullable_to_non_nullable
as int,beforeEndTimeMin: null == beforeEndTimeMin ? _self.beforeEndTimeMin : beforeEndTimeMin // ignore: cast_nullable_to_non_nullable
as int,alarmClockLinear: null == alarmClockLinear ? _self.alarmClockLinear : alarmClockLinear // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
