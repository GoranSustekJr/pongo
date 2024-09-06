import 'package:pongo/exports.dart';

class RecomendationsPhone extends StatefulWidget {
  const RecomendationsPhone({super.key});

  @override
  State<RecomendationsPhone> createState() => _RecomendationsPhoneState();
}

class _RecomendationsPhoneState extends State<RecomendationsPhone> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: Text("R E C O M E N D A T I O N S"),
      ),
    );
  }
}
