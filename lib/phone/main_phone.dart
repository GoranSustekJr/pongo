import 'package:pongo/exports.dart';
import 'package:pongo/phone/theme/theme.dart';

class MyAppPhone extends StatefulWidget {
  const MyAppPhone({super.key});

  @override
  State<MyAppPhone> createState() => _MyAppPhoneState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppPhoneState? state =
        context.findAncestorStateOfType<_MyAppPhoneState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppPhoneState extends State<MyAppPhone> {
  Locale? locale;

  setLocale(Locale local) {
    setState(() {
      locale = local;
    });
  }

  @override
  void initState() {
    super.initState();
    mainContext.value = context;
    getLocale();
  }

  getLocale() async {
    String? local = await Storage().getLocale();

    setState(() {
      locale = Locale(local.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotification(
      child: MaterialApp(
        title: 'Pongo',
        debugShowCheckedModeBanner: false,
        supportedLocales: L10n.all,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme().dark,
        showSemanticsDebugger: false,
        home: const SafeArea(
          bottom: false,
          top: false,
          child: Background(
            child: AuthRedirectPhone(),
          ),
        ),
      ),
    );
  }
}
