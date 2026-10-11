import 'dart:convert';

import 'coordinates.dart';

/// A catalog star with J2000 coordinates.
class Star {
  const Star({
    required this.position,
    required this.magnitude,
    this.colorIndex,
    this.properName,
    this.constellation,
    this.bayer,
    this.hip,
  });

  final Equatorial position;
  final double magnitude;

  /// B-V colour index; negative = blue-white, > 1.2 = orange/red.
  final double? colorIndex;
  final String? properName;
  final String? constellation;
  final String? bayer;
  final int? hip;

  String get id => hip != null ? 'HIP$hip' : '${position.ra}_${position.dec}';

  /// "Betelgeuse", or "α Ori" when there's no proper name, else "HIP 1234".
  String get displayName {
    if (properName != null) return properName!;
    if (bayer != null && constellation != null) {
      final parts = bayer!.split('-');
      final greek = _greek[parts.first] ?? parts.first;
      final suffix = parts.length > 1 ? parts[1] : '';
      return '$greek$suffix $constellation';
    }
    return hip != null ? 'HIP $hip' : 'Star';
  }
}

const _greek = {
  'Alp': 'α', 'Bet': 'β', 'Gam': 'γ', 'Del': 'δ', 'Eps': 'ε', 'Zet': 'ζ', //
  'Eta': 'η', 'The': 'θ', 'Iot': 'ι', 'Kap': 'κ', 'Lam': 'λ', 'Mu': 'μ',
  'Nu': 'ν', 'Xi': 'ξ', 'Omi': 'ο', 'Pi': 'π', 'Rho': 'ρ', 'Sig': 'σ',
  'Tau': 'τ', 'Ups': 'υ', 'Phi': 'φ', 'Chi': 'χ', 'Psi': 'ψ', 'Ome': 'ω',
};

class Constellation {
  const Constellation({
    required this.id,
    required this.name,
    required this.labelPosition,
    required this.lines,
  });

  final String id;
  final String name;
  final Equatorial labelPosition;

  /// Polylines of J2000 points forming the stick figure.
  final List<List<Equatorial>> lines;
}

class SkyCatalog {
  const SkyCatalog({
    required this.stars,
    required this.constellations,
    required this.attributions,
  });

  final List<Star> stars;
  final List<Constellation> constellations;
  final List<String> attributions;

  static const empty = SkyCatalog(
    stars: [],
    constellations: [],
    attributions: [],
  );

  /// Parses the JSON produced by `tool/build_sky_catalog.mjs`.
  factory SkyCatalog.fromJson(String starsJson, String constellationsJson) {
    final s = jsonDecode(starsJson) as Map<String, dynamic>;
    final c = jsonDecode(constellationsJson) as Map<String, dynamic>;

    final stars = [
      for (final r in (s['rows'] as List).cast<List<dynamic>>())
        Star(
          position: Equatorial(
            (r[0] as num).toDouble(),
            (r[1] as num).toDouble(),
          ),
          magnitude: (r[2] as num).toDouble(),
          colorIndex: (r[3] as num?)?.toDouble(),
          properName: r[4] as String?,
          constellation: r[5] as String?,
          bayer: r[6] as String?,
          hip: r[7] as int?,
        ),
    ];

    Equatorial pt(List<dynamic> p) =>
        Equatorial((p[0] as num).toDouble(), (p[1] as num).toDouble());

    final constellations = [
      for (final m
          in (c['constellations'] as List).cast<Map<String, dynamic>>())
        Constellation(
          id: m['id'] as String,
          name: m['name'] as String,
          labelPosition: pt(m['label'] as List),
          lines: [
            for (final seg in (m['lines'] as List).cast<List<dynamic>>())
              [for (final p in seg.cast<List<dynamic>>()) pt(p)],
          ],
        ),
    ];

    return SkyCatalog(
      stars: stars,
      constellations: constellations,
      attributions: [s['source'] as String, c['source'] as String],
    );
  }

  Star? starByName(String name) {
    final q = name.toLowerCase();
    for (final s in stars) {
      if (s.properName?.toLowerCase() == q) return s;
    }
    return null;
  }
}
