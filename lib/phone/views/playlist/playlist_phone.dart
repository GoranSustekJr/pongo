import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/playlist/tiles/playlist_song_tile.dart';
import 'package:pongo/shared/utils/API%20requests/playlist_tracks.dart';

class PlaylistPhone extends StatefulWidget {
  final Playlist playlist;
  const PlaylistPhone({super.key, required this.playlist});

  @override
  State<PlaylistPhone> createState() => _PlaylistPhoneState();
}

class _PlaylistPhoneState extends State<PlaylistPhone> {
  // Show body
  bool showBody = false;

  // Tracks
  List tracks = [];

  @override
  void initState() {
    super.initState();
    getTracks();
  }

  void getTracks() async {
    final data = await PlaylistSpotify().get(context, widget.playlist.id);

    setState(() {
      tracks = data["items"];
      showBody = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
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
                  flexibleSpace: appBarBlur(),
                ),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: Scaffold.of(context).appBarMaxHeight == null
                          ? MediaQuery.of(context).padding.top +
                              AppBar().preferredSize.height +
                              20
                          : Scaffold.of(context).appBarMaxHeight! + 20,
                      left: 15,
                      right: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        razw(MediaQuery.of(context).size.width),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: widget.playlist.image,
                            cacheManager: CacheManagerImage(),
                            fit: BoxFit.cover,
                          ),
                        ),
                        razh(15),
                        Text(widget.playlist.name),
                        razh(50),
                        ListView.builder(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom),
                          itemCount: tracks.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return PlaylistSongTile(
                              track: tracks[index],
                              first: index == 0,
                              last: index == tracks.length - 1,
                              function: () {},
                            );
                          },
                        ),
                        razh(15),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : loadingScaffold(context),
    );
  }
}
