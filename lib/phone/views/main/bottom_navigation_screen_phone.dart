import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/home_phone.dart';
import 'package:pongo/phone/views/library/library_phone.dart';
import 'package:pongo/phone/views/library/library_main_phone.dart';
import 'package:pongo/phone/views/settings/settings_main_phone.dart';

import '../bottom navigation bar/bottom_navigation_bar.dart';
import '../home/home_main_phone.dart';

class BottomNavigationScreenPhone extends StatefulWidget {
  const BottomNavigationScreenPhone({super.key});

  @override
  State<BottomNavigationScreenPhone> createState() =>
      _BottomNavigationScreenPhoneState();
}

class _BottomNavigationScreenPhoneState
    extends State<BottomNavigationScreenPhone>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final homeNavigatorKey = GlobalKey<NavigatorState>();
  final libraryHomeNavigatorKey = GlobalKey<NavigatorState>();
  final settingsNavigatorKey = GlobalKey<NavigatorState>();

  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages = [
      HomeMainPhone(homeNavigatorKey: homeNavigatorKey),
      LibraryMainPhone(libraryHomeNavigatorKey: libraryHomeNavigatorKey),
      SettingsMainPhone(settingsHomeNavigatorKey: settingsNavigatorKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const Bottom(),
      body: ValueListenableBuilder(
        valueListenable: navigationBarIndex,
        builder: (context, index, child) {
          return Stack(
            children: [
              IndexedStack(
                index: navigationBarIndex.value,
                children: pages,
              ),
            ],
          );
        },
      ),
    );
  }
}
