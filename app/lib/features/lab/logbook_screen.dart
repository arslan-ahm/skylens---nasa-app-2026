import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/sensors/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/observation_form.dart';
import '../../core/widgets/states.dart';
import '../../data/logbook/logbook_repository.dart';

final _logProvider = StreamProvider(
  (ref) => ref.watch(logbookRepositoryProvider).watch(),
);

class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(logbookRepositoryProvider);
    final loc =
        ref.read(observerLocationProvider).value ?? LocationService.fallback;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.xl,
          0,
          Space.xl,
          MediaQuery.viewInsetsOf(ctx).bottom + Space.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New observation',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: Space.lg),
              ObservationForm(
                onSubmit: (d) {
                  final now = DateTime.now();
                  repo.save(
                    Observation(
                      id: now.microsecondsSinceEpoch.toString(),
                      time: now,
                      target: d.target,
                      notes: d.notes,
                      skyQuality: d.skyQuality,
                      equipment: d.equipment,
                      latitude: loc.observer.latitude,
                      longitude: loc.observer.longitude,
                    ),
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(_logProvider);
    final t = SkyTokens.of(context);
    final hasItems = log.value?.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky diary'),
        actions: [
          IconButton(
            tooltip: 'Copy as CSV',
            icon: const Icon(Icons.file_copy_outlined),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: ref.read(logbookRepositoryProvider).toCsv(),
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logbook copied as CSV')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: hasItems
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Log'),
              tooltip: 'Log an observation',
            )
          : null,
      body: AsyncView(
        value: log,
        builder: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No observations yet',
                message:
                    'Record what you saw. Time and place are added for you.',
                action: FilledButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log an observation'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.lg,
                  Space.gutter,
                  96,
                ),
                children: [
                  GroupCard(
                    children: [
                      for (final o in items)
                        Dismissible(
                          key: ValueKey(o.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: t.danger.withValues(alpha: 0.2),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: Space.xl),
                            child: Icon(Icons.delete_outline, color: t.danger),
                          ),
                          onDismissed: (_) =>
                              ref.read(logbookRepositoryProvider).delete(o.id),
                          child: ListTile(
                            leading: const IconBadge(Icons.visibility_outlined),
                            trailing: IconButton(
                              tooltip: 'Delete ${o.target}',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(logbookRepositoryProvider)
                                  .delete(o.id),
                            ),
                            title: Text(o.target),
                            subtitle: Text(
                              [
                                    DateFormat.yMMMd().add_Hm().format(
                                      o.time.toLocal(),
                                    ),
                                    ?o.equipment,
                                  ].join(' · ') +
                                  (o.notes.isEmpty ? '' : '\n${o.notes}'),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Swipe left or tap the bin to delete an entry.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
