import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/sensors/location_service.dart';
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
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: ObservationForm(
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(_logProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        actions: [
          IconButton(
            tooltip: 'Copy CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: ref.read(logbookRepositoryProvider).toCsv(),
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('CSV copied')));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      body: AsyncView(
        value: log,
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No observations yet',
                message: 'Tap “Log” to record what you saw.',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final o = items[i];
                  return Dismissible(
                    key: ValueKey(o.id),
                    onDismissed: (_) =>
                        ref.read(logbookRepositoryProvider).delete(o.id),
                    child: ListTile(
                      title: Text(o.target),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_Hm().format(o.time.toLocal())} · ${o.equipment ?? ''}'
                        '${o.notes.isEmpty ? '' : '\n${o.notes}'}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
