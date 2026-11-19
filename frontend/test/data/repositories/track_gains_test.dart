import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/repositories/player/track_gains.dart';
import 'package:pongo/data/services/api/api_client.dart';
import 'package:pongo/data/services/database/track_gains_table.dart';
import 'package:pongo/utils/result.dart';

class _FakeTable extends Fake implements TrackGainsTable {
  final stored = <String, double>{};

  @override
  Future<Map<String, double>> query(List<String> stids) async => {
    for (final s in stids)
      if (stored.containsKey(s)) s: stored[s]!,
  };

  @override
  Future<void> upsert(Map<String, double> gains) async => stored.addAll(gains);
}

class _FakeServer extends Fake implements ApiClient {
  final gains = <String, double>{};
  final asked = <List<String>>[];
  bool offline = false;

  @override
  Future<Result<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final stids = (body['stids'] as List).cast<String>();
    asked.add(stids);
    if (offline) return Result.error(Exception('offline'));
    return Result.ok({
      'gains': {
        for (final s in stids)
          if (gains.containsKey(s)) s: gains[s],
      },
    });
  }
}

void main() {
  late _FakeTable table;
  late _FakeServer server;
  late DateTime now;
  late TrackGains gains;

  setUp(() {
    table = _FakeTable();
    server = _FakeServer()..gains.addAll({'a': -3, 'b': -5});
    now = DateTime(2026);
    gains = TrackGains(apiClient: server, table: table, now: () => now);
  });

  test('fetches unknown gains once and stores them for offline use', () async {
    await gains.prefetch(['a', 'b']);
    expect(await gains.gainFor('a'), -3);
    expect(server.asked, [
      ['a', 'b'],
    ]);
    expect(table.stored, {'a': -3, 'b': -5});
  });

  test('uses stored gains without asking the server', () async {
    table.stored['a'] = -1;
    server.offline = true;
    expect(await gains.gainFor('a'), -1);
    expect(server.asked, isEmpty);
  });

  test(
    'asks again about a track the server lacked only after a while',
    () async {
      await gains.prefetch(['new']);
      await gains.prefetch(['new']);
      expect(server.asked, hasLength(1));

      server.gains['new'] = -2;
      now = now.add(const Duration(minutes: 2));
      expect(await gains.gainFor('new'), -2);
    },
  );

  test('has no gain while offline', () async {
    server.offline = true;
    expect(await gains.gainFor('a'), isNull);
  });
}
