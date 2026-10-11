/// Where a piece of data came from. Every data card in the UI should show
/// this (source, time, licence, and whether it's cached or mock).
class DataProvenance {
  const DataProvenance({
    required this.source,
    required this.fetchedAt,
    this.url,
    this.license,
    this.origin = DataOrigin.live,
    this.note,
  });

  final String source;
  final DateTime fetchedAt;
  final String? url;
  final String? license;
  final DataOrigin origin;

  /// Limitations or confidence notes, e.g. "positions accurate to ~1′".
  final String? note;

  DataProvenance copyWith({
    DataOrigin? origin,
    DateTime? fetchedAt,
    String? note,
  }) => DataProvenance(
    source: source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    url: url,
    license: license,
    origin: origin ?? this.origin,
    note: note ?? this.note,
  );
}

enum DataOrigin { live, cache, mock, computed }

/// A value plus its provenance. Repositories return this instead of bare data.
class Sourced<T> {
  const Sourced(this.data, this.provenance);

  final T data;
  final DataProvenance provenance;

  Sourced<R> map<R>(R Function(T) f) => Sourced(f(data), provenance);
}
