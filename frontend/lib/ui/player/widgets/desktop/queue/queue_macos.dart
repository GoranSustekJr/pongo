import 'package:flutter/material.dart';

import '../../../view_models/player_view_model.dart';
import 'queue_body_macos.dart';

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
    final player = context.player;
    return StreamBuilder(
      stream: player.queueStream,
      builder: (context, snapshot) {
        final queue = snapshot.data;
        return StreamBuilder(
          stream: player.shuffleIndicesStream,
          builder: (context, snap) {
            final shuffleIndices = snap.data;
            return StreamBuilder(
              stream: player.shuffleEnabledStream,
              builder: (context, snp) {
                final shuffleModeEnabled =
                    (snp.data ?? false) &&
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
