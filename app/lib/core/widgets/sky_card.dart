import 'package:flutter/material.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'design_components.dart';
import 'source_badge.dart';

/// DESIGN_TOKENS.md card surface: flat Graphite, 20px radius, no border or shadow.
/// Optional line icon, title, subtitle, body, category tag and an
/// attribution footer.
class SkyCard extends StatelessWidget {
  const SkyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.child,
    this.category,
    this.provenance,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? child;

  /// Small uppercase tag at the bottom ("Planet", "Live data"...).
  final String? category;
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: t.ink, size: 24),
                          const SizedBox(height: 16),
                        ],
                        Text(title, style: text.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: text.bodyLarge!.copyWith(color: t.inkMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (child != null) ...[const SizedBox(height: 16), child!],
              if (category != null) ...[
                const SizedBox(height: 16),
                CategoryTag(category!),
              ],
              if (provenance != null) ...[
                const SizedBox(height: 16),
                const Divider(),
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

/// A label/value pair on a hairline ("Magnitude ........ −2.4").
class FactRow extends StatelessWidget {
  const FactRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final style = skyText(16, 1.6, 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: style.copyWith(color: t.inkMuted)),
          ),
          Text(value, style: style.copyWith(color: t.ink)),
        ],
      ),
    );
  }
}
