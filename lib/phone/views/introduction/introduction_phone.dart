import 'package:intro_slider/intro_slider.dart';
import 'package:pongo/exports.dart';

class IntroductionPhone extends StatefulWidget {
  const IntroductionPhone({super.key});

  @override
  State<IntroductionPhone> createState() => _IntroductionPhoneState();
}

class _IntroductionPhoneState extends State<IntroductionPhone> {
  // List of images
  List<ContentConfig> contentConfig = [];

  // Locale
  String locale = "en";

  // Text
  Map en = {
    "Pongo": "Pongo",
    "tapasongtoplayholdasongtodomore":
        "• Tap a song to play\n• Hold a song to do more",
    "tapthebottomsongtoopenplayingcontrollcenter":
        "• Tap the bottom song to open playing controll center\n• Hold the bottom song to halt the player",
    "tapunderthedurationslideronthetexttoshowthewholealbum":
        "• Tap under the duration slider on the text\n( ALLES ZU VIEL ) to show the whole album",
    "tapfarlefttoshowlyricstaptherrepeatbuttontorepeat":
        "• Tap far left to show lyrics\n• Tap the repeat button to repeat one song or the whole queue\n• Tap on the three dots to do more\n• Tap on far right to show queuelyrics",
    "tapfarlefttohidelyricstapon-/+":
        "• Tap far left to hide lyrics\n• Tap on -/+ icons to change text timing\n• Tap on the text timing ( 0.0s ) to reset it to 0.0s\n• Hold the text timing to save it\n• Tap on the right icon to change to static lyrics",
    "tapfarlefttoshowlyricstapinthemiddletohidethequeue":
        "• Tap far left to show lyrics\n• Tap in the middle to hide the queue\n• Tap on far right to do more\n• Hold and wait to enable reordering of the queue tracks",
    "theflagsymbolmeansthataplaylist":
        "• The flag symbol means that a playlist already contains the track\n• Tap on the bottom left to create a playlis",
    "enjoy": "Enjoy",
  };
  Map hr = {
    "Pongo": "Pongo",
    "tapasongtoplayholdasongtodomore":
        "• Dodirni pjesmu za reprodukciju\n• Drži pjesmu za više opcija",
    "tapthebottomsongtoopenplayingcontrollcenter":
        "• Dodirni donju pjesmu za otvaranje kontrolnog centra za reprodukciju\n• Drži donju pjesmu za zaustavljanje reproduktora",
    "tapunderthedurationslideronthetexttoshowthewholealbum":
        "• Dodirni ispod klizača trajanja na tekstu\n( SVE JE PREVIŠE ) za prikaz cijelog albuma",
    "tapfarlefttoshowlyricstaptherrepeatbuttontorepeat":
        "• Dodirni krajnje lijevo za prikaz stihova\n• Dodirni gumb za ponavljanje kako bi ponovio jednu pjesmu ili cijeli redoslijed\n• Dodirni tri točkice za više opcija\n• Dodirni krajnje desno za prikaz redoslijeda stihova",
    "tapfarlefttohidelyricstapon-/+":
        "• Dodirni krajnje lijevo za skrivanje stihova\n• Dodirni ikone -/+ za promjenu vremena teksta\n• Dodirni vrijeme teksta ( 0.0s ) za resetiranje na 0.0s\n• Drži vrijeme teksta za spremanje\n• Dodirni desnu ikonu za prelazak na statične stihove",
    "tapfarlefttoshowlyricstapinthemiddletohidethequeue":
        "• Dodirni krajnje lijevo za prikaz stihova\n• Dodirni u sredini za skrivanje reda\n• Dodirni krajnje desno za više opcija\n• Drži i pričekaj za omogućavanje preuređivanja pjesama u redu",
    "theflagsymbolmeansthataplaylist":
        "• Simbol zastave znači da popis za reprodukciju već sadrži pjesmu\n• Dodirni donji lijevi kut za stvaranje popisa za reprodukciju",
    "enjoy": "Uživaj",
  };
  Map de = {
    "Pongo": "Pongo",
    "tapasongtoplayholdasongtodomore":
        "• Tippe auf ein Lied, um es abzuspielen\n• Halte ein Lied gedrückt, um mehr Optionen zu sehen",
    "tapthebottomsongtoopenplayingcontrollcenter":
        "• Tippe auf das unterste Lied, um das Kontrollzentrum zu öffnen\n• Halte das unterste Lied gedrückt, um den Player zu stoppen",
    "tapunderthedurationslideronthetexttoshowthewholealbum":
        "• Tippe unter dem Dauerschieberegler auf den Text\n( ALLES ZU VIEL ), um das gesamte Album anzuzeigen",
    "tapfarlefttoshowlyricstaptherrepeatbuttontorepeat":
        "• Tippe ganz links, um die Texte anzuzeigen\n• Tippe auf den Wiederholen-Button, um ein Lied oder die gesamte Warteschlange zu wiederholen\n• Tippe auf die drei Punkte, um weitere Optionen zu sehen\n• Tippe ganz rechts, um die Warteschlange zu sehen",
    "tapfarlefttohidelyricstapon-/+":
        "• Tippe ganz links, um die Texte auszublenden\n• Tippe auf die Symbole -/+ , um das Timing des Textes zu ändern\n• Tippe auf das Timing des Textes ( 0.0s ), um es auf 0.0s zurückzusetzen\n• Halte das Timing des Textes gedrückt, um es zu speichern\n• Tippe auf das rechte Symbol, um zu statischen Texten zu wechseln",
    "tapfarlefttoshowlyricstapinthemiddletohidethequeue":
        "• Tippe ganz links, um die Texte anzuzeigen\n• Tippe in der Mitte, um die Warteschlange auszublenden\n• Tippe ganz rechts, um mehr Optionen zu sehen\n• Halte gedrückt und warte, um das Neuanordnen der Titel in der Warteschlange zu ermöglichen",
    "theflagsymbolmeansthataplaylist":
        "• Das Flaggensymbol bedeutet, dass eine Playlist den Titel bereits enthält\n• Tippe unten links, um eine Playlist zu erstellen",
    "enjoy": "Viel Spaß",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    initConfig();
    initLocale();
  }

  initLocale() async {
    final loc = await Storage().getLocale();
    setState(() {
      locale = loc ?? "en";
    });
  }

  void initConfig() {
    if (kIsIOS) {
      initIOSConfig();
    } else if (kIsAndroid) {
      initAndroidConfig();
    }
  }

  void initIOSConfig() {}

  void initAndroidConfig() {}

  Widget titleText(String txt) {
    return Container(
      decoration: BoxDecoration(
        color: Col.background,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text(
          txt,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      height: size.height,
      width: size.width,
      decoration: AppConstants().backgroundBoxDecoration,
      child: IntroSlider(
        key: UniqueKey(),
        listContentConfig: [
          const ContentConfig(
            backgroundFilterOpacity: 0,
            backgroundImage: 'assets/images/pongo_logo_tranparent.png',
            title: "Pongo",
            marginTitle: EdgeInsets.zero,
          ),
          ContentConfig(
              backgroundImage: 'assets/images/intro/hold_on_image.jpeg',
              maxLineTitle: 2,
              marginTitle: EdgeInsets.zero,
              widgetTitle: titleText(locale == "en"
                  ? en["tapasongtoplayholdasongtodomore"]
                  : locale == "hr"
                      ? hr["tapasongtoplayholdasongtodomore"]
                      : de["tapasongtoplayholdasongtodomore"])),
          ContentConfig(
            backgroundImage: 'assets/images/intro/playling_details.jpeg',
            maxLineTitle: 2,
            marginTitle: EdgeInsets.zero,
            widgetTitle: titleText(locale == "en"
                ? en["tapthebottomsongtoopenplayingcontrollcenter"]
                : locale == "hr"
                    ? hr["tapthebottomsongtoopenplayingcontrollcenter"]
                    : de["tapthebottomsongtoopenplayingcontrollcenter"]),
            widgetDescription: ClipRRect(
              borderRadius: BorderRadius.circular(27.5),
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27.5),
                    border: Border.all(color: Colors.white),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27.5),
                    child: Image.asset(
                        'assets/images/intro/tap_to_show_details.jpeg'),
                  )),
            ),
            marginDescription: EdgeInsets.zero,
          ),
          ContentConfig(
            backgroundImage: 'assets/images/intro/playling_details.jpeg',
            maxLineTitle: 2,
            marginTitle: EdgeInsets.zero,
            widgetTitle: titleText(locale == "en"
                ? en["tapunderthedurationslideronthetexttoshowthewholealbum"]
                : locale == "hr"
                    ? hr[
                        "tapunderthedurationslideronthetexttoshowthewholealbum"]
                    : de[
                        "tapunderthedurationslideronthetexttoshowthewholealbum"]),
            widgetDescription: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27.5),
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: Image.asset('assets/images/intro/tap_on_album.jpg')),
            ),
            marginDescription: EdgeInsets.zero,
          ),
          ContentConfig(
            backgroundImage: 'assets/images/intro/playling_details.jpeg',
            maxLineTitle: 2,
            marginTitle: EdgeInsets.zero,
            widgetTitle: titleText(locale == "en"
                ? en["tapfarlefttoshowlyricstaptherrepeatbuttontorepeat"]
                : locale == "hr"
                    ? hr["tapfarlefttoshowlyricstaptherrepeatbuttontorepeat"]
                    : de["tapfarlefttoshowlyricstaptherrepeatbuttontorepeat"]),
            widgetDescription: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27.5),
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child:
                      Image.asset('assets/images/intro/other_controls.jpeg')),
            ),
            marginDescription: EdgeInsets.zero,
          ),
          ContentConfig(
            backgroundImage: 'assets/images/intro/lyrics.jpeg',
            maxLineTitle: 2,
            marginTitle: const EdgeInsets.only(top: kToolbarHeight),
            widgetTitle: titleText(locale == "en"
                ? en["tapfarlefttohidelyricstapon-/+"]
                : locale == "hr"
                    ? hr["tapfarlefttohidelyricstapon-/+"]
                    : de["tapfarlefttohidelyricstapon-/+"]),
            widgetDescription: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27.5),
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: Image.asset('assets/images/intro/lyrics_buttons.jpg')),
            ),
            marginDescription: EdgeInsets.zero,
          ),
          ContentConfig(
            backgroundImage: 'assets/images/intro/queue.jpeg',
            maxLineTitle: 2,
            marginTitle: const EdgeInsets.only(top: kToolbarHeight),
            widgetTitle: titleText(locale == "en"
                ? en["tapfarlefttoshowlyricstapinthemiddletohidethequeue"]
                : locale == "hr"
                    ? hr["tapfarlefttoshowlyricstapinthemiddletohidethequeue"]
                    : de["tapfarlefttoshowlyricstapinthemiddletohidethequeue"]),
          ),
          ContentConfig(
            backgroundImage: 'assets/images/intro/add_to_playlist.jpeg',
            maxLineTitle: 2,
            marginTitle: const EdgeInsets.only(top: kToolbarHeight),
            widgetTitle: titleText(locale == "en"
                ? en["theflagsymbolmeansthataplaylist"]
                : locale == "hr"
                    ? hr["theflagsymbolmeansthataplaylist"]
                    : de["theflagsymbolmeansthataplaylist"]),
          ),
          ContentConfig(
            backgroundFilterOpacity: 0,
            backgroundImage: 'assets/images/pongo_logo_tranparent.png',
            title: locale == "en"
                ? en["enjoy"]
                : locale == "hr"
                    ? hr["enjoy"]
                    : de["enjoy"],
            marginTitle: EdgeInsets.zero,
          ),
        ],
        // Indicator
        indicatorConfig: IndicatorConfig(
          colorActiveIndicator: Col.onIcon,
          colorIndicator: Col.fadeIcon,
          typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
        ),

        // Navigation bar
        navigationBarConfig: NavigationBarConfig(
          navPosition: NavPosition.bottom,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewPadding.top > 0 ? 20 : 10,
            bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? 20 : 10,
          ),
          backgroundColor: Colors.transparent,
        ),
        onDonePress: () {
          Navigator.of(context).pop();
        },

        // Button
        renderSkipBtn: Text(
          AppLocalizations.of(context)!.skip,
          style: const TextStyle(
              color: Colors.white, overflow: TextOverflow.ellipsis),
        ),
        renderDoneBtn: Text(
          AppLocalizations.of(context)!.done,
          style: const TextStyle(
              color: Colors.white, overflow: TextOverflow.ellipsis),
        ),
        renderNextBtn: Text(
          AppLocalizations.of(context)!.next,
          style: const TextStyle(
              color: Colors.white, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

/* */
}
