import 'package:flutter/material.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'design_components.dart';
import 'motion.dart';
import 'source_badge.dart';

/// Standard content card: optional icon badge, title, subtitle, trailing
/// action, body, and an attribution footer for any data it shows.
class SkyCard extends StatelessWidget {
  const SkyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone = Tone.primary,
    this.trailing,
    this.child,
    this.provenance,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Tone tone;
  final Widget? trailing;
  final Widget? child;
  final DataProvenance? provenance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    IconBadge(icon!, tone: tone, size: 36),
                    const SizedBox(width: Space.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: text.titleMedium),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: text.bodyMedium!.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (child != null) ...[const SizedBox(height: Space.md), child!],
              if (provenance != null) ...[
                const SizedBox(height: Space.md),
                const Divider(),
                const SizedBox(height: Space.sm),
                SourceBadge(provenance!),
              ],
            ],
          ),
        ),
      ),
    );
    return onTap == null ? card : Pressable(child: card);
  }
}

/// Label / value row ("Magnitude ........ −2.4"), numbers in tabular figures.
class FactRow extends StatelessWidget {
  const FactRow(this.label, this.value, {super.key, this.divider = true});

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: divider
              ? BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.outline)),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium!.copyWith(color: t.textMuted),
                ),
              ),
              const SizedBox(width: Space.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
