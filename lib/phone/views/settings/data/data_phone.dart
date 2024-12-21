import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pongo/exports.dart';

class DataPhone extends StatefulWidget {
  const DataPhone({super.key});

  @override
  State<DataPhone> createState() => _DataPhoneState();
}

class _DataPhoneState extends State<DataPhone> {
  // Show body
  bool showBody = false;

  // Market
  String market = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    initPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  initPreferences() async {
    final mark = await Storage().getMarket();
    setState(() {
      market = mark ?? 'US';
      showBody = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      backButton(context),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    razw(size.width),
                    razh(AppBar().preferredSize.height / 2),
                    Text(
                      AppLocalizations.of(context)!.data,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    razh(AppBar().preferredSize.height),
                    settingsText(AppLocalizations.of(context)!.cache),
                    settingsTile(
                      context,
                      true,
                      false,
                      AppIcons.audioPlayer,
                      AppIcons.trash,
                      AppLocalizations.of(context)!.clearaudioplayercache,
                      AppLocalizations.of(context)!.clearyouraudioplayercache,
                      () async {
                        await AudioPlayer.clearAssetCache();
                      },
                    ),
                    settingsTile(
                        context,
                        false,
                        false,
                        AppIcons.image,
                        AppIcons.trash,
                        AppLocalizations.of(context)!.clearimagecache,
                        AppLocalizations.of(context)!.clearyourassetimagecache,
                        () async {
                      DefaultCacheManager manager = DefaultCacheManager();
                      manager.emptyCache();
                      PaintingBinding.instance.imageCache.clear();
                    }),
                    settingsTile(
                      context,
                      false,
                      true,
                      CupertinoIcons.clear_thick,
                      AppIcons.trash,
                      AppLocalizations.of(context)!.clearallcache,
                      AppLocalizations.of(context)!.clearallappcache,
                      () async {
                        await AudioPlayer.clearAssetCache();
                        DefaultCacheManager manager = DefaultCacheManager();
                        manager.emptyCache();
                        PaintingBinding.instance.imageCache.clear();
                      },
                    ),
                  ],
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
