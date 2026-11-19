import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/repositories/player/mix_refill.dart';
import 'package:pongo/utils/result.dart';

MixEntry entry(String id) => (track: {'id': id}, durationSeconds: 200);

/// A server the test answers by hand, and the queue the mix appends to.
class _Mix {
  _Mix() {
    refill = MixRefill(
      fetch: ({required seeds, required exclude, required count}) {
        requests.add((seeds: seeds, exclude: exclude));
        final answer = Completer<Result<List<MixEntry>>>();
        answers.add(answer);
        return answer.future;
      },
      append: (entries) async {
        queue.addAll([for (final e in entries) '${e.track['id']}']);
        refill.update(queue, position);
      },
      retryDelay: (_) => Duration.zero,
    );
  }

  late final MixRefill refill;
  final requests = <({List<String> seeds, List<String> exclude})>[];
  final answers = <Completer<Result<List<MixEntry>>>>[];
  final queue = <String>['seed'];
  int position = 0;

  void playAt(int index) {
    position = index;
    refill.update(queue, position);
  }

  Future<void> answer(List<String> ids) async {
    answers.last.complete(Result.ok([for (final id in ids) entry(id)]));
    await pumpEventQueue();
  }
}

void main() {
  test('starts fetching right away and sends the latest tracks first', () {
    final mix = _Mix();
    mix.queue.addAll(['a', 'b']);
    mix.refill.start();
    mix.playAt(2);
    expect(mix.requests.single.seeds, ['b', 'a', 'seed']);
    expect(mix.requests.single.exclude, ['seed', 'a', 'b']);
  });

  test('waits until two or fewer tracks are left', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    await mix.answer(['a', 'b', 'c']);
    expect(mix.queue, ['seed', 'a', 'b', 'c']);
    expect(mix.requests, hasLength(1));

    mix.playAt(1);
    expect(mix.requests, hasLength(2));
  });

  test('spamming next sends only one request at a time', () async {
    final mix = _Mix()..refill.start();
    mix.queue.addAll(['a', 'b']);
    for (var i = 0; i <= 2; i++) {
      mix.playAt(i);
    }
    expect(mix.requests, hasLength(1));

    await mix.answer(['c', 'd', 'e']);
    expect(mix.queue, ['seed', 'a', 'b', 'c', 'd', 'e']);
    // Still at the end of the old queue, but three tracks are left now
    expect(mix.requests, hasLength(1));
  });

  test('fetches again if playback moved on while it was fetching', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    mix.queue.addAll(['a', 'b', 'c']);
    mix.playAt(3);
    await mix.answer(['d']);
    expect(mix.requests, hasLength(2));
  });

  test('drops an answer that comes after the mix stopped', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    mix.refill.stop();
    await mix.answer(['a', 'b', 'c']);
    expect(mix.queue, ['seed']);
  });

  test('drops an answer for an earlier mix after a new one started', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    final stale = mix.answers.last;
    mix.refill.start();
    mix.playAt(0);
    expect(mix.requests, hasLength(2));

    stale.complete(Result.ok([entry('old')]));
    await pumpEventQueue();
    expect(mix.queue, ['seed']);
  });

  test('leaves out tracks already queued', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    await mix.answer(['seed', 'a', 'a']);
    expect(mix.queue, ['seed', 'a']);
  });

  test('tries again after a failure', () async {
    final mix = _Mix()..refill.start();
    mix.playAt(0);
    mix.answers.last.complete(Result.error(Exception('offline')));
    await pumpEventQueue();
    expect(mix.requests, hasLength(2));
    expect(mix.queue, ['seed']);
  });

  test('an exception while fetching counts as a failure', () async {
    var calls = 0;
    final refill = MixRefill(
      fetch: ({required seeds, required exclude, required count}) {
        calls++;
        return Future.error(Exception('socket closed'));
      },
      append: (_) async {},
      retryDelay: (_) => const Duration(hours: 1),
    )..start();
    refill.update(['seed'], 0);
    await pumpEventQueue();
    refill.update(['seed'], 0);
    expect(calls, 1, reason: 'waits for the retry delay');
    refill.stop();
  });

  test('does nothing when no mix is running', () {
    final mix = _Mix();
    mix.playAt(0);
    expect(mix.requests, isEmpty);
  });
}
