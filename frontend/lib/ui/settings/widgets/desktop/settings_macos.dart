import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../config/markets.dart';
import '../../../../domain/models/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../view_models/profile_view_model.dart';

/// The account and preferences, grouped like System Settings, in the content
/// area of the Mac window.
class SettingsMacos extends StatefulWidget {
  /// Creates the settings page.
  const SettingsMacos({super.key});

  @override
  State<SettingsMacos> createState() => _SettingsMacosState();
}

class _SettingsMacosState extends State<SettingsMacos> {
  late final ProfileViewModel profile;

  @override
  void initState() {
    super.initState();
    profile = ProfileViewModel(auth: context.read());
  }

  @override
  void dispose() {
    profile.dispose();
    super.dispose();
  }

  Future<void> _save(AppSettings Function(AppSettings) change) =>
      context.read<AppSettingsViewModel>().update(change);

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: l10n.deleteaccount,
      message:
          '${l10n.bydeletingyouraccountyouwilldeleteallyourprivilegesifpayingpremium}'
          '\n\n${l10n.areyousurezouwanttodeleteyouraccount}',
      confirm: l10n.delete,
    );
    if (confirmed) await profile.deleteAccount();
  }

  Widget _switch(bool value, AppSettings Function(bool) change) =>
      MacosSwitch(value: value, onChanged: (on) => _save((_) => change(on)));

  Widget _count(int value, AppSettings Function(int) change) =>
      MacosPopupButton<int>(
        value: value,
        items: [
          for (var number = 0; number <= 50; number++)
            MacosPopupMenuItem(value: number, child: Text('$number')),
        ],
        onChanged: (number) {
          if (number != null) _save((_) => change(number));
        },
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.settings;
    return MacosScaffold(
      backgroundColor: Col.transp,
      toolBar: ToolBar(
        title: Text(l10n.settings),
        decoration: const BoxDecoration(color: Col.transp),
        enableBlur: true,
        automaticallyImplyLeading: false,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListenableBuilder(
                        listenable: profile,
                        builder: (context, _) => _ProfileCard(
                          profile: profile,
                          onDelete: _deleteAccount,
                        ),
                      ),
                      _Section(
                        title: l10n.searchpreferences,
                        rows: [
                          _Row(
                            label: l10n.searchmarket,
                            control: MacosPopupButton<String>(
                              value: settings.market,
                              items: [
                                for (final market in markets)
                                  MacosPopupMenuItem(
                                    value: market,
                                    child: Text(market),
                                  ),
                              ],
                              onChanged: (market) {
                                if (market == null) return;
                                _save((s) => s.copyWith(market: market));
                              },
                            ),
                          ),
                          _Row(
                            label: l10n.artists,
                            subtitle: l10n.howmanyartistsshownwhensearching,
                            control: _count(
                              settings.searchArtistCount,
                              (n) => settings.copyWith(searchArtistCount: n),
                            ),
                          ),
                          _Row(
                            label: l10n.albums,
                            subtitle: l10n.howmanyalbumsshownwhensearching,
                            control: _count(
                              settings.searchAlbumCount,
                              (n) => settings.copyWith(searchAlbumCount: n),
                            ),
                          ),
                          _Row(
                            label: l10n.tracks,
                            subtitle: l10n.howmanytracksshownwhensearching,
                            control: _count(
                              settings.searchTrackCount,
                              (n) => settings.copyWith(searchTrackCount: n),
                            ),
                          ),
                          _Row(
                            label: l10n.playlists,
                            subtitle: l10n.howmanyplaylistsshownwhensearching,
                            control: _count(
                              settings.searchPlaylistCount,
                              (n) => settings.copyWith(searchPlaylistCount: n),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.startpage,
                        rows: [
                          _Row(
                            label: l10n.showhistory,
                            subtitle: l10n.showhistoryonstartpage,
                            control: _switch(
                              settings.enableHistory,
                              (on) => settings.copyWith(enableHistory: on),
                            ),
                          ),
                          _Row(
                            label: l10n.showexplore,
                            subtitle: l10n.showexploreonstartpage,
                            control: _switch(
                              settings.enableCategories,
                              (on) => settings.copyWith(enableCategories: on),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.lyrics,
                        rows: [
                          _Row(
                            label: l10n.enablelyrics,
                            control: _switch(
                              settings.enableLyrics,
                              (on) => settings.copyWith(enableLyrics: on),
                            ),
                          ),
                          _Row(
                            label: l10n.prefersyncedlyrics,
                            control: _switch(
                              settings.useSyncedLyrics,
                              (on) => settings.copyWith(useSyncedLyrics: on),
                            ),
                          ),
                          _Row(
                            label: l10n.synctimedelay,
                            subtitle: l10n.usesynctimedelay,
                            control: _switch(
                              settings.useSyncTimeDelay,
                              (on) => settings.copyWith(useSyncTimeDelay: on),
                            ),
                          ),
                          _Row(
                            label: l10n.lyircstextalignment,
                            control: MacosPopupButton<TextAlign>(
                              value: settings.lyricsTextAlign,
                              items: [
                                MacosPopupMenuItem(
                                  value: TextAlign.left,
                                  child: Text(l10n.lefttextalign),
                                ),
                                MacosPopupMenuItem(
                                  value: TextAlign.center,
                                  child: Text(l10n.centertextalign),
                                ),
                                MacosPopupMenuItem(
                                  value: TextAlign.right,
                                  child: Text(l10n.righttextalign),
                                ),
                              ],
                              onChanged: (align) {
                                if (align == null) return;
                                _save(
                                  (s) => s.copyWith(lyricsTextAlign: align),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.audioplayer,
                        rows: [
                          _Row(
                            label: l10n.mix,
                            subtitle:
                                l10n.usemixfeaturewhenplayingsearchedmusic,
                            control: _switch(
                              settings.useMix,
                              (on) => settings.copyWith(useMix: on),
                            ),
                          ),
                          _Row(
                            label: l10n.audioplayercaching,
                            subtitle: l10n.letaudioplayercachethesongs,
                            control: _switch(
                              settings.useCacheAudioSource,
                              (on) =>
                                  settings.copyWith(useCacheAudioSource: on),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.images,
                        rows: [
                          _Row(
                            label: l10n.imagecaching,
                            control: _switch(
                              settings.cacheImages,
                              (on) => settings.copyWith(cacheImages: on),
                            ),
                          ),
                          _Row(
                            label: l10n.clearimagecache,
                            control: PushButton(
                              controlSize: ControlSize.regular,
                              secondary: true,
                              onPressed: () async {
                                await DefaultCacheManager().emptyCache();
                                PaintingBinding.instance.imageCache.clear();
                              },
                              child: Text(l10n.delete),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.sleep,
                        rows: [
                          _Row(
                            label: l10n.linearsleepin,
                            subtitle:
                                l10n.linearlydecreasevolumewhenusingsleepin,
                            control: _switch(
                              settings.linearSleepIn,
                              (on) => settings.copyWith(linearSleepIn: on),
                            ),
                          ),
                          _Row(
                            label: l10n.linearalarm,
                            subtitle: l10n.linearlyincreasevolumewhenusingalarm,
                            control: _switch(
                              settings.linearWakeUp,
                              (on) => settings.copyWith(linearWakeUp: on),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.userinterface,
                        rows: [
                          _Row(
                            label: l10n.useanimations,
                            subtitle:
                                l10n.turnoffifanimationsaretoohardonthedevice,
                            control: _switch(
                              settings.useAnimations,
                              (on) => settings.copyWith(useAnimations: on),
                            ),
                          ),
                        ],
                      ),
                      _Section(
                        title: l10n.about,
                        rows: [
                          _Row(
                            label: 'pongo.group@gmail.com',
                            subtitle: l10n.contactusviamail,
                            control: PushButton(
                              controlSize: ControlSize.regular,
                              secondary: true,
                              onPressed: () => Clipboard.setData(
                                const ClipboardData(
                                  text: 'pongo.group@gmail.com',
                                ),
                              ),
                              child: const MacosIcon(
                                CupertinoIcons.doc_on_doc,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onDelete});

  final ProfileViewModel profile;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    final user = profile.profile;
    final picture = user?.picture ?? '';
    return _Section(
      rows: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 56,
                  child: picture.isEmpty
                      ? const ColoredBox(
                          color: MacosColors.systemGrayColor,
                          child: MacosIcon(
                            CupertinoIcons.person_fill,
                            size: 30,
                            color: MacosColors.white,
                          ),
                        )
                      : Image.network(picture, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: theme.typography.title2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: theme.typography.body.copyWith(
                        color: secondaryTextMacos,
                      ),
                    ),
                  ],
                ),
              ),
              PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: profile.signOut,
                child: Text(l10n.signout),
              ),
            ],
          ),
        ),
        _Row(
          label: l10n.deleteyouraccount,
          control: PushButton(
            controlSize: ControlSize.regular,
            secondary: true,
            onPressed: onDelete,
            child: Text(
              l10n.deleteaccount,
              style: const TextStyle(color: MacosColors.systemRedColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// A group of rows on a rounded background, under an optional [title].
class _Section extends StatelessWidget {
  const _Section({this.title, required this.rows});

  final String? title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                title!,
                style: theme.typography.headline.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: MacosColors.systemGrayColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: MacosColors.systemGrayColor.withAlpha(40),
              ),
            ),
            child: Column(
              children: [
                for (final (index, row) in rows.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: MacosColors.systemGrayColor.withAlpha(50),
                    ),
                  row,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A setting: its [label], an optional explanation and its [control].
class _Row extends StatelessWidget {
  const _Row({required this.label, this.subtitle, required this.control});

  final String label;
  final String? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.body),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.typography.caption1.copyWith(
                      color: secondaryTextMacos,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}
