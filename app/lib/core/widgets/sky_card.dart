import 'package:flutter/material.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'source_badge.dart';

/// The standard content card: optional icon, title, subtitle, body and an
/// attribution footer.
class SkyCard extends StatelessWidget {
  const SkyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.child,
    this.provenance,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget? child;
  final DataProvenance? provenance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (iconColor ?? t.accent).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor ?? t.accent),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: text.bodySmall!.copyWith(color: t.inkMuted),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (child != null) ...[const SizedBox(height: 12), child!],
              if (provenance != null) ...[
                const SizedBox(height: 8),
                SourceBadge(provenance!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A label/value pair for detail sheets ("Magnitude  −2.4").
class FactRow extends StatelessWidget {
  const FactRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: t.inkMuted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
