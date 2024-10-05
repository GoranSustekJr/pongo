import '../../../exports.dart';

class ClearQueue {
  Future<void> clear(context) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    // Stop audio
    await audioServiceHandler.pause();
    await audioServiceHandler.stop();

    // Clear the queue
    audioServiceHandler.queue.value.clear();

    // Clear the playlist
    await audioServiceHandler.playlist.clear();
  }
}
