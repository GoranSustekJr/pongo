import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
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

  final l10n = AppLocalizations.of(context);
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    maxHeight: 600,
    maxWidth: 600,
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
  if (croppedFile == null) return null;
  return File(croppedFile.path).readAsBytes();
}
