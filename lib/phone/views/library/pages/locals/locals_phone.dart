import 'package:pongo/exports.dart';

class LocalsPhone extends StatefulWidget {
  const LocalsPhone({super.key});

  @override
  State<LocalsPhone> createState() => _LocalsPhoneState();
}

class _LocalsPhoneState extends State<LocalsPhone> {
  // Show body
  bool showBody = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? const Center(
              child: Text("Offline songs"),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}
