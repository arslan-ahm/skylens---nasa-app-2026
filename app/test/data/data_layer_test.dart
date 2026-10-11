import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:skylens/core/network/cached_fetcher.dart';
import 'package:skylens/core/network/provenance.dart';
import 'package:skylens/data/logbook/logbook_repository.dart';
import 'package:skylens/data/nasa/nasa_models.dart';

dynamic fixture(String name) =>
    jsonDecode(File('assets/mock/$name').readAsStringSync());

/// Serves files from the real assets folder, like rootBundle would.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

/// Dio adapter that returns a canned response or fails like a dead network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  String? body;
  String contentType = 'application/json';
  int status = 200;
  bool timeout = false;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? _,
    Future<void>? _,
  ) async {
    calls++;
    if (timeout) {
      throw DioException.connectionTimeout(
        requestOptions: o,
        timeout: const Duration(seconds: 8),
      );
    }
    if (body == null) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    return ResponseBody.fromString(
      body!,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('NASA model parsing (captured fixtures)', () {
    test('APOD', () {
      // The captured fixture shows the Oct 2026 API breakage (logo + "NASA
      // Science" title); the model must flag it instead of showing the logo.
      final a = Apod.fromJson(fixture('apod.json') as Map<String, dynamic>);
      expect(a.degraded, isTrue);
      expect(a.hasUsableImage, isFalse);
      expect(a.title, 'Astronomy Picture of the Day');
      expect(a.explanation, isNotEmpty);

      final ok = Apod.fromJson({
        'title': 'Eagle Nebula',
        'url': 'https://apod.nasa.gov/x.jpg',
        'media_type': 'image',
      });
      expect(ok.degraded, isFalse);
      expect(ok.hasUsableImage, isTrue);
    });

    test('NeoWs feed', () {
      final j = fixture('neo_feed.json') as Map<String, dynamic>;
      final all = [
        for (final l in (j['near_earth_objects'] as Map).values)
          for (final o in (l as List).cast<Map<String, dynamic>>())
            NearEarthObject.fromJson(o),
      ];
      expect(all, isNotEmpty);
      expect(all.first.missDistanceKm, greaterThan(0));
      expect(all.first.closeApproach.year, 2026);
    });

    test('DONKI notifications', () {
      final list = (fixture('donki_notifications.json') as List)
          .cast<Map<String, dynamic>>()
          .map(SpaceWeatherNotice.fromJson)
          .toList();
      expect(list, isNotEmpty);
      expect(list.first.issued.year, 2026);
      expect(list.map((n) => n.typeLabel), contains('Solar flare'));
    });

    test('Image library search', () {
      final imgs = NasaImage.listFromSearch(
        fixture('images_search.json') as Map<String, dynamic>,
      );
      expect(imgs, isNotEmpty);
      expect(imgs.first.previewUrl, startsWith('http'));
    });
  });

  group('CachedFetcher fallback chain', () {
    late Box<dynamic> cache;
    late _FakeAdapter adapter;
    late CachedFetcher fetcher;
    final prov = DataProvenance(source: 'Test', fetchedAt: DateTime(2026));

    setUpAll(
      () => Hive.init(Directory.systemTemp.createTempSync('skylens_test').path),
    );
    setUp(() async {
      cache = await Hive.openBox<dynamic>(
        'cache_${DateTime.now().microsecondsSinceEpoch}',
      );
      adapter = _FakeAdapter('{"ok": 1}');
      fetcher = CachedFetcher(
        Dio()..httpClientAdapter = adapter,
        cache,
        bundle: _DiskBundle(),
      );
    });

    test('live, then fresh cache without a second request', () async {
      final a = await fetcher.getJson(
        url: 'https://x.test/a',
        provenance: prov,
      );
      expect(a.provenance.origin, DataOrigin.live);
      final b = await fetcher.getJson(
        url: 'https://x.test/a',
        provenance: prov,
      );
      expect(b.provenance.origin, DataOrigin.cache);
      expect(adapter.calls, 1);
    });

    test('stale cache is used when offline', () async {
      await fetcher.getJson(url: 'https://x.test/b', provenance: prov);
      adapter.body = null;
      final r = await fetcher.getJson(
        url: 'https://x.test/b',
        provenance: prov,
        ttl: Duration.zero,
      );
      expect(r.provenance.origin, DataOrigin.cache);
      expect(r.data, {'ok': 1});
    });

    test('mock fixture is the last resort', () async {
      adapter.body = null;
      final r = await fetcher.getJson(
        url: 'https://x.test/c',
        provenance: prov,
        mockAsset: 'assets/mock/apod.json',
      );
      expect(r.provenance.origin, DataOrigin.mock);
      expect((r.data as Map)['title'], isNotNull);
    });

    test('HTML pages (e.g. moved endpoints) are not cached as data', () async {
      adapter
        ..body = '<!DOCTYPE html><html>Moved</html>'
        ..contentType = 'text/html';
      final r = await fetcher.getJson(
        url: 'https://x.test/d',
        provenance: prov,
        mockAsset: 'assets/mock/apod.json',
      );
      expect(r.provenance.origin, DataOrigin.mock);
      expect(cache.isEmpty, isTrue);
    });
  });

  group('CachedFetcher failure modes', () {
    late _FakeAdapter adapter;
    late CachedFetcher fetcher;
    final prov = DataProvenance(source: 'Test', fetchedAt: DateTime(2026));

    setUp(() async {
      final cache = await Hive.openBox<dynamic>(
        'fail_${DateTime.now().microsecondsSinceEpoch}',
      );
      adapter = _FakeAdapter('{"error": "x"}');
      fetcher = CachedFetcher(
        Dio()..httpClientAdapter = adapter,
        cache,
        bundle: _DiskBundle(),
      );
    });

    Future<Sourced<dynamic>> fetch(String path, {String? mock}) =>
        fetcher.getJson(
          url: 'https://x.test/$path',
          query: {'api_key': 'SECRET'},
          provenance: prov,
          mockAsset: mock,
        );

    for (final (status, reason) in [
      (403, 'API key rejected'),
      (401, 'API key rejected'),
      (429, 'Rate limit reached'),
      (503, 'Service unavailable'),
    ]) {
      test('HTTP $status falls back to sample data and says why', () async {
        adapter.status = status;
        final r = await fetch('s$status', mock: 'assets/mock/neo_feed.json');
        expect(r.provenance.origin, DataOrigin.mock);
        expect(r.provenance.note, startsWith(reason));
      });
    }

    test('timeout is reported as a slow network', () async {
      adapter.timeout = true;
      final r = await fetch('t', mock: 'assets/mock/neo_feed.json');
      expect(r.provenance.origin, DataOrigin.mock);
      expect(r.provenance.note, startsWith('Network too slow'));
    });

    test('stale data is labelled as saved, never as live', () async {
      adapter.body = '{"ok": 1}';
      await fetch('stale');
      adapter.status = 503;
      final r = await fetcher.getJson(
        url: 'https://x.test/stale',
        query: {'api_key': 'SECRET'},
        provenance: prov,
        ttl: Duration.zero,
      );
      expect(r.provenance.origin, DataOrigin.cache);
      expect(r.provenance.note, 'Service unavailable — showing saved data');
    });

    test('first launch, offline, no fixture: the error surfaces', () async {
      adapter.body = null;
      await expectLater(fetch('none'), throwsA(isA<DioException>()));
    });

    test('API keys never end up in cache keys', () async {
      adapter.body = '{"ok": 1}';
      final cache = await Hive.openBox<dynamic>(
        'keys_${DateTime.now().microsecondsSinceEpoch}',
      );
      await CachedFetcher(Dio()..httpClientAdapter = adapter, cache).getJson(
        url: 'https://x.test/k',
        query: {'api_key': 'SECRET'},
        provenance: prov,
      );
      expect(cache.keys.join(), isNot(contains('SECRET')));
    });
  });

  test('logbook round-trip and CSV escaping', () async {
    final box = await Hive.openBox<dynamic>(
      'log_${DateTime.now().microsecondsSinceEpoch}',
    );
    final repo = LogbookRepository(box);
    await repo.save(
      Observation(
        id: '1',
        time: DateTime.utc(2026, 10, 11, 20),
        target: 'Jupiter',
        latitude: 31.5,
        longitude: 74.3,
        notes: 'Four moons, "very" sharp',
        skyQuality: 4,
      ),
    );
    expect(repo.all().single.target, 'Jupiter');
    expect(repo.toCsv(), contains('"Four moons, ""very"" sharp"'));
  });
}
