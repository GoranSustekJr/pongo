import 'package:pongo/desktop/macos/views/queue/queue_body_macos.dart';
import 'package:pongo/exports.dart';

class QueueMacos extends StatefulWidget {
  final bool editQueue;
  final List<int> selectedQueueIndexes;
  final Function(int) selectQueueIndex;
  const QueueMacos({
    super.key,
    required this.editQueue,
    required this.selectedQueueIndexes,
    required this.selectQueueIndex,
  });

  @override
  State<QueueMacos> createState() => _QueueMacosState();
}

class _QueueMacosState extends State<QueueMacos> {
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    return StreamBuilder(
      stream: audioServiceHandler.queue.stream,
      builder: (context, snapshot) {
        final queue = snapshot.data;
        return StreamBuilder(
          stream: audioServiceHandler.audioPlayer.shuffleIndicesStream,
          builder: (context, snap) {
            final shuffleIndices = snap.data;
            return StreamBuilder(
              stream: audioServiceHandler.audioPlayer.shuffleModeEnabledStream,
              builder: (context, snp) {
                final shuffleModeEnabled = (snp.data ?? false) &&
                    (shuffleIndices != null
                        ? shuffleIndices.isNotEmpty
                        : false);

                return RepaintBoundary(
                  child: QueueBodyMacos(
                    shuffleModeEnabled: shuffleModeEnabled,
                    editQueue: widget.editQueue,
                    queue: queue ?? [],
                    shuffleIndices: shuffleIndices ?? [],
                    selectedQueueIndexes: widget.selectedQueueIndexes,
                    selectQueueIndex: widget.selectQueueIndex,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
