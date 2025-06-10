import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/home_phone.dart';

class HomeMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> homeNavigatorKey;
  const HomeMainPhone({super.key, required this.homeNavigatorKey});

  @override
  State<HomeMainPhone> createState() => _HomeMainPhoneState();
}

class _HomeMainPhoneState extends State<HomeMainPhone> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final canPop = widget.homeNavigatorKey.currentState?.canPop() ?? false;
        if (canPop) {
          widget.homeNavigatorKey.currentState?.pop();
          return false; // Prevent root navigator from popping (i.e. don't close the app)
        }
        return true; // Nothing to pop, let the app close
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: AppConstants().backgroundBoxDecoration,
          child: Stack(
            children: [
              Navigator(
                key: widget.homeNavigatorKey,
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => const HomePhone(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
