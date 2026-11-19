import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/space.dart';

class PlaylistHandlerBodyAddPlaylistPhone extends StatelessWidget {
  final Object? cover;
  final TextEditingController titleController;
  final Function() pickImage;
  final Function() createPlaylistFunction;
  final Function(String) onChanged;
  const PlaylistHandlerBodyAddPlaylistPhone({
    super.key,
    required this.pickImage,
    this.cover,
    required this.titleController,
    required this.createPlaylistFunction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            razh(kToolbarHeight + 30),
            liquidGlassBackground(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: kIsApple
                      ? Col.transp
                      : context.colors.primaryCard.withAlpha(200),
                ),
                child: Stack(
                  children: [
                    if (cover != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FadeInImage(
                          width: 250,
                          fit: BoxFit.cover,
                          height: 250,
                          placeholder: const AssetImage(
                            'assets/images/placeholder.png',
                          ),
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          image: switch (cover) {
                            final File file => FileImage(file),
                            final String source
                                when source.startsWith('file://') =>
                              FileImage(File.fromUri(Uri.parse(source))),
                            final String source
                                when source.startsWith('http') =>
                              NetworkImage(source),
                            final source => FileImage(File(source.toString())),
                          } as ImageProvider,
                        ),
                      ),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(360),
                          color: context.colors.primaryCard.withAlpha(200),
                        ),
                        child: iconButton(
                          Icons.camera_alt_rounded,
                          context.colors.icon,
                          size: 30,
                          pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            razh(25),
            SizedBox(
              width: size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: titleController,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    disabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    hintText: AppLocalizations.of(context).playlistname,
                  ),
                ),
              ),
            ),
            razh(25),
            textButton(
              AppLocalizations.of(context).create,
              createPlaylistFunction,
              const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
