import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/utils/calculate_image_resolution.dart';
import 'package:pongo/features/player/data/track_metadata_api.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/models/catalog/track.dart';

class AddToQueue {
  // Add a catalog track

  // Add type track
  Future<void> addTypeTrackLast(
    context,
    Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadataApi().getDuration(context, track.id);

    if (duration["duration"] == null) {
      TrackMetadataApi().checkTrackExists(
        context,
        track.id,
        doesNotExist,
        doesNowExist,
        (duration) async {
          MediaItem mediaItem = MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.add(mediaItem);
          await audioServiceHandler.playlist
              .add(audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  // Add type track
  Future<void> addTypeTrackFirst(
    context,
    Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadataApi().getDuration(context, track.id);

    if (duration["duration"] == null) {
      TrackMetadataApi().checkTrackExists(
        context,
        track.id,
        doesNotExist,
        doesNowExist,
        (duration) async {
          MediaItem mediaItem = MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              mediaItem);
          await audioServiceHandler.playlist.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          mediaItem);
      await audioServiceHandler.playlist.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  void shuffleEnabledWarning(context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    if (audioServiceHandler.audioPlayer.shuffleModeEnabled) {
      Notifications().showWarningNotification(
          context, AppLocalizations.of(context).shufflemodeison);
    }
  }
}
