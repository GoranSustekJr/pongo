import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/themes/colors.dart';
import 'library_phone.dart';

class LibraryMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> libraryHomeNavigatorKey;
  const LibraryMainPhone({super.key, required this.libraryHomeNavigatorKey});

  @override
  State<LibraryMainPhone> createState() => _LibraryMainPhoneState();
}

class _LibraryMainPhoneState extends State<LibraryMainPhone> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = widget.libraryHomeNavigatorKey.currentState;
        if (navigator?.canPop() ?? false) {
          navigator!.pop();
        } else {
          SystemNavigator.pop(); // Nothing to pop, let the app close
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: context.colors.backgroundBoxDecoration,
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
      ),
    );
  }
}
