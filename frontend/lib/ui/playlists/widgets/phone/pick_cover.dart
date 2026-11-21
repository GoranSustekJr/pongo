import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/platform.dart';
import '../../../core/notifications.dart';

/// Lets the user pick a photo and crop it to a square of at most 600 px.
///
/// Returns the image bytes, or `null` if the user cancelled.
Future<Uint8List?> pickSquareCover(BuildContext context) async {
  XFile? pickedFile;
  try {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
  } on Exception catch (e) {
    if (e.toString().contains('access_denied') && context.mounted) {
      Notifications().showWarningNotification(
        context,
        AppLocalizations.of(context).pleaseallowaccesstophotogalery,
      );
    }
    return null;
  }
  if (pickedFile == null || !context.mounted) return null;

  final cover = await squareCover(context, pickedFile.path, 600);
  return cover?.readAsBytes();
}

/// Crops the photo at [path] to a square of at most [size] px, or returns
/// `null` if the user cancelled.
///
/// Desktops have no cropper, so there the photo is only scaled down; covers
/// are always shown cropped to a square.
Future<File?> squareCover(BuildContext context, String path, int size) async {
  if (kIsDesktop) {
    final bytes = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: size,
      minHeight: size,
    );
    if (bytes == null) return null;
    final directory = await getTemporaryDirectory();
    final name = 'cover_${DateTime.now().microsecondsSinceEpoch}.jpg';
    return File(p.join(directory.path, name)).writeAsBytes(bytes);
  }

  final l10n = AppLocalizations.of(context);
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: path,
    maxHeight: size,
    maxWidth: size,
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
  return croppedFile == null ? null : File(croppedFile.path);
}
