import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/pages/local%20playlists/data%20manager/local_playlist_data_manager.dart';

class LocalPlaylistPhone extends StatelessWidget {
  final int lpid;
  final String title;
  final MemoryImage? cover;
  final String blurhash;
  final Function(MemoryImage) updateCover;
  final Function(String) updateTitle;
  const LocalPlaylistPhone({
    super.key,
    required this.lpid,
    required this.title,
    this.cover,
    required this.blurhash,
    required this.updateCover,
    required this.updateTitle,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return ChangeNotifierProvider(
      create: (_) => LocalPlaylistDataManager(
        context,
        lpid,
        title,
        cover,
        blurhash,
        updateCover,
        updateTitle,
      ),
      child: Consumer<LocalPlaylistDataManager>(
        builder: (context, localPlaylistDataManager, child) {
          return AnimatedSwitcher(
            key: ValueKey(localPlaylistDataManager),
            duration: const Duration(milliseconds: 400),
            child: localPlaylistDataManager.showBody
                ? Container(
                    child: const Center(
                      child: Text("data"),
                    ),
                  )
                : const Text("ddddd"),
          );
        },
      ),
    );
  }
}
