import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/library_phone.dart';

class LibraryMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> libraryHomeNavigatorKey;
  const LibraryMainPhone({super.key, required this.libraryHomeNavigatorKey});

  @override
  State<LibraryMainPhone> createState() => _LibraryMainPhoneState();
}

class _LibraryMainPhoneState extends State<LibraryMainPhone> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: AppConstants().backgroundBoxDecoration,
        child: Stack(
          children: [
            Navigator(
              key: widget.libraryHomeNavigatorKey,
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute(
                  builder: (context) => const LibraryPhone(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
