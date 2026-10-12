import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/motion.dart';
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
        title: const Text('Space news'),
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
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.lg,
          Space.gutter,
          Space.xxl,
        ),
        children: staggered([
          AsyncView(
            value: ref.watch(_apodProvider),
            onRetry: () => ref.invalidate(_apodProvider),
            builder: (r) => SkyCard(
              title: r.data.title,
              subtitle: 'Space picture of the day · ${r.data.date}',
              icon: Icons.photo_outlined,
              provenance: r.provenance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.data.hasUsableImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.md),
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
                  const SizedBox(height: Space.md),
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
                        "See today's picture on NASA's website",
                      ),
                    ),
                  if (r.data.copyright != null)
                    Text(
                      '© ${r.data.copyright}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          AsyncView(
            value: ref.watch(_weatherProvider),
            builder: (r) {
              final next = r.data
                  .where((h) => h.time.isAfter(DateTime.now().toUtc()))
                  .take(12)
                  .toList();
              return SkyCard(
                title: 'Will the sky be clear?',
                subtitle: 'Next 12 hours · taller bars mean clearer sky',
                icon: Icons.cloud_outlined,
                provenance: r.provenance,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final h in next)
                      Expanded(
                        child: Tooltip(
                          message:
                              '${DateFormat.Hm().format(h.time.toLocal())}: ${h.cloudCoverPct.round()}% cloud',
                          child: Column(
                            children: [
                              Container(
                                height: 48 * h.clearSkyScore + 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    t.surfaceHigh,
                                    t.primary,
                                    h.clearSkyScore,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: Space.xs),
                              Text(
                                DateFormat.H().format(h.time.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(fontSize: 11),
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
          const SizedBox(height: Space.md),
          AsyncView(
            value: ref.watch(_neoProvider),
            builder: (r) => SkyCard(
              title: 'Asteroids flying by',
              subtitle: '${r.data.length} pass Earth in the next 3 days',
              icon: Icons.track_changes,
              provenance: r.provenance,
              child: Column(
                children: [
                  for (final n in r.data.take(5))
                    FactRow(
                      '${n.name}${n.isPotentiallyHazardous ? ' · hazardous' : ''}',
                      '${n.missDistanceLunar.toStringAsFixed(1)}× Moon distance · ${n.diameterMinM.round()}–${n.diameterMaxM.round()} m',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          AsyncView(
            value: ref.watch(_donkiProvider),
            builder: (r) => SkyCard(
              title: 'Space weather',
              subtitle: '${r.data.length} solar events this week',
              icon: Icons.flare,
              tone: Tone.warning,
              provenance: r.provenance,
              child: Column(
                children: [
                  for (final n in r.data.take(5))
                    FactRow(n.typeLabel, hm.format(n.issued.toLocal())),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          AsyncView(
            value: ref.watch(_imagesProvider('jupiter')),
            builder: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Pictures of Jupiter'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Space.xs,
                  crossAxisSpacing: Space.xs,
                  children: [
                    for (final img in r.data)
                      Tooltip(
                        message: img.title,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          child: CachedNetworkImage(
                            imageUrl: img.previewUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                SourceBadge(r.provenance),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
