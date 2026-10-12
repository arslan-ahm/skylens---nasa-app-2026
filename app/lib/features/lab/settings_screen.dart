import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/motion.dart';

/// Friendly settings: how the app looks, plus "About" items. Technical
/// details (data mode, API key) sit one tap deeper in "For developers".
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.xxl,
        ),
        children: staggered([
          const SectionLabel('Look and feel'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Theme', style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Night vision keeps your eyes ready for the dark.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: Space.md),
                  for (final v in SkyThemeVariant.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: _ThemeOption(
                        variant: v,
                        selected: s.theme == v,
                        onTap: () =>
                            notifier.update((x) => x.copyWith(theme: v)),
                      ),
                    ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Text size', style: text.titleSmall),
                      ),
                      AnimatedValue(
                        '${(s.textScale * 100).round()}%',
                        style: text.labelLarge!.copyWith(
                          color: t.primary,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('A', style: text.bodySmall),
                      Expanded(
                        child: Slider(
                          value: s.textScale,
                          min: 0.9,
                          max: 1.6,
                          divisions: 7,
                          label: '${(s.textScale * 100).round()}%',
                          semanticFormatterCallback: (v) =>
                              'Text size ${(v * 100).round()} percent',
                          onChanged: (v) =>
                              notifier.update((x) => x.copyWith(textScale: v)),
                        ),
                      ),
                      Text('A', style: text.titleLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('About'),
          GroupCard(
            children: [
              ModuleTile(
                icon: Icons.palette_outlined,
                title: 'Design gallery',
                subtitle: 'Every building block of the SkyLens look',
                onTap: () => context.push('/settings/design'),
              ),
              ModuleTile(
                icon: Icons.gavel_outlined,
                title: 'Credits and licences',
                subtitle: 'Data, fonts and open-source code we use',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'SkyLens',
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(Space.sm),
                    child: SkyLensMark(size: 48),
                  ),
                ),
              ),
              ModuleTile(
                icon: Icons.code,
                title: 'For developers',
                subtitle: 'Data mode, API key and engine status',
                onTap: () => showDeveloperInfo(context),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          const Center(child: Float(child: SkyLensMark(size: 40))),
          const SizedBox(height: Space.sm),
          Center(
            child: Text(
              'SkyLens · made for curious stargazers',
              style: text.bodySmall,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Big, friendly theme choice with a live colour preview.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final SkyThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  static const _blurbs = {
    SkyThemeVariant.space: 'Deep blue night sky',
    SkyThemeVariant.nightRed: 'All red, for use outdoors at night',
    SkyThemeVariant.highContrast: 'Bold and extra clear',
  };

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final preview = switch (variant) {
      SkyThemeVariant.space => SkyTokens.space,
      SkyThemeVariant.nightRed => SkyTokens.nightRed,
      SkyThemeVariant.highContrast => SkyTokens.highContrast,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${variant.label} theme. ${_blurbs[variant]}',
      child: ExcludeSemantics(
        child: Pressable(
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.enter,
            decoration: BoxDecoration(
              color: selected ? t.primaryContainer : t.surfaceHigh,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(
                color: selected ? t.primary : t.outline,
                width: selected ? 2 : t.strokeWidth,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(Radii.lg),
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: preview.bg,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: preview.outline),
                        ),
                        child: Icon(variant.icon, color: preview.primary),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(variant.label, style: text.titleSmall),
                            Text(_blurbs[variant]!, style: text.bodySmall),
                          ],
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: Motion.medium,
                        curve: Motion.emphasized,
                        child: Icon(Icons.check_circle, color: t.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Technical status for developers, kept off the main screens.
void showDeveloperInfo(BuildContext context) {
  final demo = AppConfig.usingDemoKey;
  final mock = AppConfig.dataMode == 'mock';
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: staggered([
            Text(
              'For developers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.lg),
            MetricRow([
              MetricTile(
                label: 'Data',
                value: mock ? 'Sample' : 'Live',
                icon: Icons.wifi_tethering,
                tone: mock ? Tone.neutral : Tone.success,
              ),
              MetricTile(
                label: 'NASA key',
                value: demo ? 'Demo' : 'Personal',
                icon: demo ? Icons.warning_amber_rounded : Icons.key,
                tone: demo ? Tone.warning : Tone.success,
              ),
              const MetricTile(
                label: 'Engine',
                value: 'Offline',
                icon: Icons.offline_bolt_outlined,
                tone: Tone.primary,
              ),
            ]),
            if (demo) ...[
              const SizedBox(height: Space.md),
              Text(
                'DEMO_KEY allows 30 requests an hour. Add a personal key in '
                'app/.env.json.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ]),
        ),
      ),
    ),
  );
}
