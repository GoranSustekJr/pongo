import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/notifications.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/playlist_handler_view_model.dart';
import 'playlist_handler_body_phone.dart';

/// The overlay for creating playlists and adding tracks to them.
class PlaylistHandlerPhone extends StatefulWidget {
  /// Creates the overlay for [playlistHandler].
  const PlaylistHandlerPhone({super.key, required this.playlistHandler});

  /// What the overlay was opened to do.
  final PlaylistHandler playlistHandler;

  @override
  State<PlaylistHandlerPhone> createState() => _PlaylistHandlerPhoneState();
}

class _PlaylistHandlerPhoneState extends State<PlaylistHandlerPhone> {
  late final PlaylistHandlerViewModel viewModel;

  // Show create playlist screen
  bool showCreatePlaylist = false;

  // New playlist cover: a URL or file URI string, or a picked File
  Object? newPlaylistCover;
  final titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel = PlaylistHandlerViewModel(
      handler: widget.playlistHandler,
      playlists: context.read(),
      downloads: context.read(),
      images: context.read(),
      messages: context.read(),
    );
    if (widget.playlistHandler.function ==
        PlaylistHandlerFunction.createPlaylist) {
      newPlaylistCover = viewModel.suggestedCover;
    }
  }

  @override
  void dispose() {
    viewModel.dispose();
    titleController.dispose();
    super.dispose();
  }

  void close() => context.shell.playlistHandler.value = null;

  Future<void> createPlaylist() async {
    final cover = switch (newPlaylistCover) {
      final File file => file.path,
      final String source => source,
      _ => null,
    };
    final done = await viewModel.createPlaylist(
      titleController.text,
      cover: cover,
    );
    if (done && mounted) close();
  }

  Future<void> addTracksToPlaylists() async {
    final done = await viewModel.addToSelectedPlaylists();
    if (done && mounted) close();
  }

  Future<void> pickImage() async {
    XFile? pickedFile;
    try {
      pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } on Exception catch (e) {
      if (e.toString().contains('access_denied') && mounted) {
        Notifications().showWarningNotification(
          context,
          AppLocalizations.of(context).pleaseallowaccesstophotogalery,
        );
      }
      return;
    }
    if (pickedFile == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    // Crop the image to a square
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      maxHeight: 500,
      maxWidth: 500,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.cropimage,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: l10n.cropimage,
          cancelButtonTitle: l10n.cancel,
          doneButtonTitle: l10n.okey,
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() => newPlaylistCover = File(croppedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final onlyCreatePlaylist =
        widget.playlistHandler.function ==
        PlaylistHandlerFunction.createPlaylist;
    return ClipRRect(
      child: BackdropFilter(
        filter: appBlur(context, 12.5),
        child: Container(
          height: size.height,
          width: size.width,
          color: context.readSettings.useBlur
              ? Colors.black.withAlpha(75)
              : context.colors.realBackground.withAlpha(225),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Scaffold(
              key: ValueKey(widget.playlistHandler),
              resizeToAvoidBottomInset: false,
              extendBodyBehindAppBar: true,
              extendBody: true,
              appBar: AppBar(),
              body: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => PlaylistHandlerBodyPhone(
                  playlistHandlerTracks: widget.playlistHandler.track,
                  working: viewModel.working,
                  createPlaylistFunction: createPlaylist,
                  titleController: titleController,
                  addTracksToPlaylists: addTracksToPlaylists,
                  newPlaylistCover: newPlaylistCover,
                  currentPlaylists: viewModel.currentPlaylists,
                  selectedPlaylists: viewModel.selectedPlaylists,
                  playlistTrackMap: viewModel.playlistTracks,
                  // When not on create playlist page
                  showCreatePlaylist: showCreatePlaylist || onlyCreatePlaylist,
                  // When not only showing the create playlist page
                  onlyCreatePlaylist: onlyCreatePlaylist,
                  changeCreatePlaylist: () {
                    setState(() => showCreatePlaylist = !showCreatePlaylist);
                  },
                  selectPlaylist: viewModel.selectPlaylist,
                  pickImage: pickImage,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
