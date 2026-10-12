import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'design_components.dart';
import 'motion.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Semantics(
          liveRegion: true,
          label: message ?? 'Loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              if (message != null) ...[
                const SizedBox(height: Space.lg),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: t.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty or error state: tinted icon, title, explanation, optional action.
/// The message should say what the user can do next.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.nights_stay_outlined,
    this.tone = Tone.primary,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Tone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Float(child: IconBadge(icon, tone: tone, size: 56)),
              const SizedBox(height: Space.lg),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  message!,
                  style: text.bodyMedium!.copyWith(color: t.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Space.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly error: what happened in plain words and what to do, with the
/// technical error tucked behind "Show details".
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  static (String, String) _explain(Object e) {
    final s = '$e'.toLowerCase();
    if (s.contains('socket') ||
        s.contains('connection') ||
        s.contains('offline') ||
        s.contains('network') ||
        s.contains('timeout')) {
      return (
        "Can't reach space right now",
        'Check your internet connection and try again.',
      );
    }
    if (s.contains('permission') || s.contains('denied')) {
      return (
        'SkyLens needs your permission',
        'Allow access in your phone settings, then try again.',
      );
    }
    return ('Something went a bit wrong', 'Please try again in a moment.');
  }

  @override
  Widget build(BuildContext context) {
    final (title, message) = _explain(error);
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      tone: Tone.warning,
      title: title,
      message: message,
      action: Column(
        children: [
          if (onRetry != null)
            Pressable(
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ),
          _Details('$error'),
        ],
      ),
    );
  }
}

class _Details extends StatefulWidget {
  const _Details(this.text);

  final String text;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(_open ? 'Hide details' : 'Show details'),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.enter,
          child: _open
              ? Text(
                  widget.text,
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
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
