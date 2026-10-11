import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sky_card.dart';
import '../../core/widgets/source_badge.dart';
import '../../core/widgets/states.dart';
import '../../data/nasa/nasa_models.dart';

final _apodProvider = FutureProvider(
  (ref) => ref.watch(nasaRepositoryProvider).apod(),
);
final _neoProvider = FutureProvider(
  (ref) => ref
      .watch(nasaRepositoryProvider)
      .closeApproaches(start: DateTime.now(), days: 3),
);
final _donkiProvider = FutureProvider(
  (ref) => ref.watch(nasaRepositoryProvider).spaceWeather(),
);
final _imagesProvider = FutureProvider.family(
  (ref, String q) =>
      ref.watch(nasaRepositoryProvider).searchImages(q, pageSize: 9),
);
final _weatherProvider = FutureProvider((ref) async {
  final loc = await ref.watch(observerLocationProvider.future);
  return ref
      .watch(weatherRepositoryProvider)
      .hourly(loc.observer.latitude, loc.observer.longitude);
});

class NasaScreen extends ConsumerWidget {
  const NasaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SkyTokens.of(context);
    final hm = DateFormat.MMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NASA & open data'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_apodProvider);
              ref.invalidate(_neoProvider);
              ref.invalidate(_donkiProvider);
              ref.invalidate(_weatherProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncView(
            value: ref.watch(_apodProvider),
            onRetry: () => ref.invalidate(_apodProvider),
            builder: (r) => SkyCard(
              title: r.data.title,
              subtitle: 'Astronomy Picture of the Day · ${r.data.date}',
              icon: Icons.photo_outlined,
              provenance: r.provenance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.data.hasUsableImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: r.data.url,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox(
                          height: 60,
                          child: Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    r.data.explanation,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.data.degraded)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(Apod.webPage)),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text(
                        'Image unavailable from API — view on science.nasa.gov',
                      ),
                    ),
                  if (r.data.copyright != null)
                    Text(
                      '© ${r.data.copyright}',
                      style: TextStyle(color: t.inkMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AsyncView(
            value: ref.watch(_weatherProvider),
            builder: (r) {
              final next = r.data
                  .where((h) => h.time.isAfter(DateTime.now().toUtc()))
                  .take(12)
                  .toList();
              return SkyCard(
                title: 'Sky conditions, next 12 h',
                icon: Icons.cloud_outlined,
                provenance: r.provenance,
                child: Row(
                  children: [
                    for (final h in next)
                      Expanded(
                        child: Tooltip(
                          message:
                              '${DateFormat.Hm().format(h.time.toLocal())}: ${h.cloudCoverPct.round()}% cloud',
                          child: Column(
                            children: [
                              Container(
                                height: 40 * h.clearSkyScore + 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                color: Color.lerp(
                                  t.inkMuted,
                                  t.horizon,
                                  h.clearSkyScore,
                                ),
                              ),
                              Text(
                                DateFormat.H().format(h.time.toLocal()),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          AsyncView(
            value: ref.watch(_neoProvider),
            builder: (r) => SkyCard(
              title: 'Asteroid close approaches',
              subtitle: '${r.data.length} in the next 3 days',
              icon: Icons.blur_on,
              provenance: r.provenance,
              child: Column(
                children: [
                  for (final n in r.data.take(5))
                    FactRow(
                      '${n.name}${n.isPotentiallyHazardous ? ' ⚠' : ''}',
                      '${n.missDistanceLunar.toStringAsFixed(1)} LD · ${n.diameterMinM.round()}–${n.diameterMaxM.round()} m',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AsyncView(
            value: ref.watch(_donkiProvider),
            builder: (r) => SkyCard(
              title: 'Space weather (DONKI)',
              subtitle: '${r.data.length} notifications in 7 days',
              icon: Icons.flare,
              provenance: r.provenance,
              child: Column(
                children: [
                  for (final n in r.data.take(5))
                    FactRow(n.typeLabel, hm.format(n.issued.toLocal())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AsyncView(
            value: ref.watch(_imagesProvider('jupiter')),
            builder: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NASA Image Library: "jupiter"',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    for (final img in r.data)
                      Tooltip(
                        message: img.title,
                        child: CachedNetworkImage(
                          imageUrl: img.previewUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
                SourceBadge(r.provenance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
