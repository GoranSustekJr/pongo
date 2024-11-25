import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class AppIcons {
  static final settings =
      kIsApple ? CupertinoIcons.settings : CupertinoIcons.gear_alt_fill;

  static const profile = CupertinoIcons.person_fill;

  static final mail = kIsApple ? CupertinoIcons.mail : Icons.mail;

  static final playlist =
      kIsApple ? CupertinoIcons.music_albums : Icons.queue_music_rounded;

  static final premium =
      kIsApple ? CupertinoIcons.checkmark_circle : Icons.verified_rounded;

  static const search = CupertinoIcons.search;

  static final library =
      kIsApple ? CupertinoIcons.music_albums : Icons.my_library_music_rounded;

  static const libraryFill = CupertinoIcons.music_albums_fill;

  static final musicQueue =
      kIsApple ? CupertinoIcons.collections : Icons.queue_music_rounded;

  static final musicQueueFill =
      kIsApple ? CupertinoIcons.collections_solid : Icons.queue_music_rounded;

  static const info = CupertinoIcons.info_circle;
  static const addToQueue = CupertinoIcons.plus_square_on_square;

  static final download =
      kIsApple ? CupertinoIcons.cloud_download : Icons.cloud_download_rounded;

  static const musicAlbums = CupertinoIcons.music_albums;

  static const heart = CupertinoIcons.heart;

  static const heartFill = CupertinoIcons.heart_fill;

  static const heartSlash = CupertinoIcons.heart_slash;

  static const play = CupertinoIcons.play_fill;

  static const shuffle = CupertinoIcons.shuffle;

  static final edit = kIsApple ? CupertinoIcons.pencil : Icons.edit;

  static const world = CupertinoIcons.globe;

  static final blankArtist =
      kIsApple ? CupertinoIcons.person : Icons.person_rounded;

  static const blankAlbum = CupertinoIcons.music_albums;

  static final blankTrack =
      kIsApple ? CupertinoIcons.music_note : Icons.music_note_rounded;

  static final trash = kIsApple ? CupertinoIcons.trash : Icons.delete;

  static const halt = CupertinoIcons.stop_fill;

  static const more = CupertinoIcons.ellipsis_vertical;

  static final editImage =
      kIsApple ? CupertinoIcons.photo_camera : Icons.photo_camera_rounded;

  static const burger = CupertinoIcons.bars;

  static const checkmark = CupertinoIcons.checkmark_circle;

  static const uncheckmark = CupertinoIcons.circle;

  static final preferences =
      kIsApple ? CupertinoIcons.slider_horizontal_3 : Icons.tune_rounded;

  static final cancel =
      kIsApple ? CupertinoIcons.xmark_circle_fill : Icons.cancel;

  static const x = CupertinoIcons.xmark;

  static const lyricsFill = CupertinoIcons.quote_bubble_fill;

  static const lyrics = CupertinoIcons.quote_bubble;

  static const audioPlayer = CupertinoIcons.music_house_fill;

  static const image = CupertinoIcons.photo_fill;

  static const firstToQueue = CupertinoIcons.rectangle_on_rectangle_angled;
  static const lastToQueue = CupertinoIcons.rectangle_on_rectangle;

  static const hide = CupertinoIcons.eye_slash;

  static const hideFill = CupertinoIcons.eye_slash_fill;

  static const unhideFill = CupertinoIcons.eye_fill;

  static const loading = CupertinoIcons.timelapse;

  static const repeat = CupertinoIcons.repeat;

  static const repeatOne = CupertinoIcons.repeat_1;
}
