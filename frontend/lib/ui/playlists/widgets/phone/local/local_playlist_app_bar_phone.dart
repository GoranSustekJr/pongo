import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/phone/buttons/back_like_button.dart';

class LocalPlaylistAppBarPhone extends StatelessWidget {
  final String title;
  final MemoryImage? cover;
  final bool edit;
  final double scrollControllerOffset;
  final Function() changeCover;
  final Function() changeTitle;
  const LocalPlaylistAppBarPhone({
    super.key,
    required this.title,
    required this.cover,
    required this.edit,
    required this.scrollControllerOffset,
    required this.changeCover,
    required this.changeTitle,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SliverAppBar(
      snap: false,
      collapsedHeight: kToolbarHeight,
      expandedHeight: MediaQuery.of(context).size.height / 2,
      floating: false,
      pinned: true,
      backgroundColor: context.readSettings.useBlur
          ? Col.transp
          : context.colors.realBackground.withAlpha(
              ((MediaQuery.of(context).size.height / 2 <= scrollControllerOffset
                          ? 1
                          : scrollControllerOffset /
                                (MediaQuery.of(context).size.height / 2)) *
                      Dimens.noBlur)
                  .toInt(),
            ),
      stretch: true,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          backButton(context),
          Flexible(
            child: SizedBox(
              width: size.width,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: edit
                    ? SizedBox(
                        key: const ValueKey(true),
                        child: textButton(
                          AppLocalizations.of(context).changename,
                          changeTitle,
                          const TextStyle(color: Colors.white),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          key: const ValueKey(false),
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ),
          backLikeButton(
            context,
            edit ? AppIcons.editImage : AppIcons.edit,
            changeCover,
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        title: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Opacity(
            opacity:
                MediaQuery.of(context).size.height / 2 <= scrollControllerOffset
                ? 1
                : scrollControllerOffset /
                      (MediaQuery.of(context).size.height / 2),
            child: BackdropFilter(
              filter: appBlur(context, 10),
              child: Container(),
            ),
          ),
        ),
        background: Stack(
          children: [
            Center(
              child: SizedBox(
                width: size.width - 60,
                height: size.width - 60,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: cover != null
                          ? Image.memory(cover!.bytes)
                          : Container(
                              width: size.width - 60,
                              height: size.width - 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: context.colors.primaryCard.withAlpha(
                                  200,
                                ),
                              ),
                              child: const Center(
                                child: Icon(AppIcons.blankAlbum, size: 50),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
