import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:hive_ce/hive_ce.dart';

import '../config/app_config.dart';
import 'provenance.dart';

Dio createDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ),
);

/// Fetches JSON with a resilient fallback chain:
/// fresh cache -> network -> stale cache -> bundled mock fixture.
///
/// In `DATA_MODE=mock` it goes straight to the fixture.
class CachedFetcher {
  CachedFetcher(this._dio, this._cache, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final Dio _dio;
  final Box<dynamic> _cache;
  final AssetBundle _bundle;

  Future<Sourced<dynamic>> getJson({
    required String url,
    Map<String, dynamic>? query,
    required DataProvenance provenance,
    Duration ttl = const Duration(hours: 1),
    String? mockAsset,
  }) async {
    final key = Uri.parse(url)
        .replace(queryParameters: _stringify(query))
        .toString();
    // Don't key the cache on secrets.
    final cacheKey = key.replaceAll(RegExp(r'api_key=[^&]*'), 'api_key=*');

    if (AppConfig.useMockData && mockAsset != null) {
      return _mock(mockAsset, provenance);
    }

    final cached = _cache.get(cacheKey) as Map?;
    final cachedAt = cached == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cached['at'] as int);
    if (cached != null && DateTime.now().difference(cachedAt!) < ttl) {
      return Sourced(
        jsonDecode(cached['body'] as String),
        provenance.copyWith(origin: DataOrigin.cache, fetchedAt: cachedAt),
      );
    }

    try {
      final res = await _dio.get<dynamic>(url, queryParameters: query);
      // Throws FormatException for HTML error/redirect pages, so they are
      // never cached as data.
      final body = res.data is String
          ? jsonDecode(res.data as String)
          : res.data;
      final now = DateTime.now();
      await _cache.put(cacheKey, {
        'at': now.millisecondsSinceEpoch,
        'body': jsonEncode(body),
      });
      return Sourced(
        body,
        provenance.copyWith(origin: DataOrigin.live, fetchedAt: now),
      );
    } on Exception catch (e) {
      if (e is! DioException && e is! FormatException) rethrow;
      debugPrint('CachedFetcher: $e for $cacheKey');
      final reason = failureReason(e);
      if (cached != null) {
        return Sourced(
          jsonDecode(cached['body'] as String),
          provenance.copyWith(
            origin: DataOrigin.cache,
            fetchedAt: cachedAt,
            note: '$reason — showing saved data',
          ),
        );
      }
      if (mockAsset != null) {
        return _mock(
          mockAsset,
          provenance,
          note: '$reason — showing sample data',
        );
      }
      rethrow;
    }
  }

  Future<Sourced<dynamic>> _mock(
    String asset,
    DataProvenance p, {
    String? note,
  }) async {
    final body = jsonDecode(await _bundle.loadString(asset));
    return Sourced(
      body,
      p.copyWith(
        origin: DataOrigin.mock,
        fetchedAt: DateTime.now(),
        note: note ?? 'Sample data',
      ),
    );
  }

  /// Short, user-facing reason a request failed, so a fallback card can say
  /// what to do next (fix the key, wait, or reconnect) instead of always
  /// claiming to be offline.
  static String failureReason(Object e) {
    if (e is FormatException) return 'Service changed or unavailable';
    if (e is! DioException) return 'Request failed';
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return 'API key rejected';
    if (code == 429) return 'Rate limit reached';
    if (code != null && code >= 500) return 'Service unavailable';
    if (code != null) return 'Request failed ($code)';
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'Network too slow',
      _ => 'Offline',
    };
  }

  static Map<String, String>? _stringify(Map<String, dynamic>? q) =>
      q?.map((k, v) => MapEntry(k, '$v'));
}
