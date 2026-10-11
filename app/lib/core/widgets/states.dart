import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'design_components.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: skyText(14, 1.43, 0.28).copyWith(color: t.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state: a small globe diagram with the line icon at its centre,
/// a title, a Slate message and an optional ghost-pill action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.nights_stay_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlobeDiagram(
              size: 120,
              rings: 2,
              child: Icon(icon, size: 28, color: t.ink),
            ),
            const SizedBox(height: 16),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: text.bodyLarge!.copyWith(color: t.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'Something went wrong',
    message: '$error',
    action: onRetry == null
        ? null
        : GhostPillButton(label: 'Try again', onPressed: onRetry),
  );
}

/// Renders an [AsyncValue] with the standard loading/error states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loadingMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => LoadingState(message: loadingMessage),
    error: (e, _) => ErrorState(error: e, onRetry: onRetry),
  );
}
