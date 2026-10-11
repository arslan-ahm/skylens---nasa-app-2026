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
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? _,
    Future<void>? _,
  ) async {
    calls++;
    if (body == null) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    return ResponseBody.fromString(
      body!,
      200,
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
