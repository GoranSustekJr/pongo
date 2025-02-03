import 'package:pongo/exports.dart';

class AboutPhone extends StatefulWidget {
  const AboutPhone({super.key});

  @override
  State<AboutPhone> createState() => _AboutPhoneState();
}

class _AboutPhoneState extends State<AboutPhone> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
        body: const Center(
          child: Text("pongo.group@gmail.com"),
        ),
      ),
    );
  }
}
