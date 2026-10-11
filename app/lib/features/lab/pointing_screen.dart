import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/astro/coordinates.dart';
import '../../core/astro/sky_engine.dart';
import '../../core/providers.dart';
import '../../core/sensors/pointing_math.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/object_sheet.dart';

/// Proves the AR pipeline: camera preview + sensor pose + projection.
/// Calibrate by centring a known bright object (Moon, Sun, planet) and
/// tapping "Calibrate on …".
class PointingScreen extends ConsumerStatefulWidget {
  const PointingScreen({super.key});

  @override
  ConsumerState<PointingScreen> createState() => _PointingScreenState();
}

class _PointingScreenState extends ConsumerState<PointingScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _camera = ctrl);
    } catch (e) {
      if (mounted) setState(() => _cameraError = '$e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  void _calibrate(DevicePose pose, SkyObject target) {
    final measured = pose.cameraDirection.az;
    final delta = calibrationOffset(
      measuredAz: measured,
      trueAz: target.horizontal.az,
    );
    ref
        .read(appSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(compassOffsetDeg: s.compassOffsetDeg + delta),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compass corrected by ${delta.toStringAsFixed(1)}° using ${target.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pose = ref.watch(devicePoseProvider).value;
    final snap = ref.watch(skySnapshotProvider).value;
    final settings = ref.watch(appSettingsProvider);
    final t = SkyTokens.of(context);

    final candidates = snap?.objects
        .where((o) => o.isAboveHorizon && o.magnitude < 1.5)
        .toList();
    final calibTarget = (candidates == null || candidates.isEmpty)
        ? null
        : candidates.first;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pointing / AR test'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera?.value.isInitialized ?? false)
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _camera!.value.previewSize?.height ?? 1,
                  height: _camera!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_camera!),
                ),
              ),
            )
          else
            Center(
              child: Text(
                _cameraError ?? 'Starting camera…',
                style: TextStyle(color: t.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          if (pose != null && snap != null)
            LayoutBuilder(
              builder: (context, box) {
                final proj = SkyProjector(
                  pose: pose,
                  viewport: box.biggest,
                  verticalFovDeg: settings.cameraFovDeg,
                );
                return GestureDetector(
                  onTapUp: (d) {
                    SkyObject? best;
                    var bestD = 40.0;
                    for (final o in snap.objects) {
                      final p = proj.projectVisible(o.horizontal);
                      if (p == null || o.magnitude > 3.5) continue;
                      final dist = (p - d.localPosition).distance;
                      if (dist < bestD) {
                        bestD = dist;
                        best = o;
                      }
                    }
                    if (best != null) showSkyObjectSheet(context, object: best);
                  },
                  child: CustomPaint(
                    size: box.biggest,
                    painter: _OverlayPainter(proj, snap, t),
                  ),
                );
              },
            ),
          // Centre reticle.
          IgnorePointer(
            child: Center(
              child: Icon(
                Icons.add,
                color: t.accent.withValues(alpha: 0.7),
                size: 32,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              color: t.surface.withValues(alpha: 0.85),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pose == null
                          ? 'No orientation sensors (web/emulator?)'
                          : 'Pointing ${pose.cameraDirection.az.toStringAsFixed(0)}° ${pose.cameraDirection.compassPoint}, '
                                '${pose.cameraDirection.alt.toStringAsFixed(0)}° up',
                    ),
                    Row(
                      children: [
                        const Text('FOV'),
                        Expanded(
                          child: Slider(
                            value: settings.cameraFovDeg,
                            min: 35,
                            max: 90,
                            label: '${settings.cameraFovDeg.round()}°',
                            divisions: 55,
                            onChanged: (v) => ref
                                .read(appSettingsProvider.notifier)
                                .update((s) => s.copyWith(cameraFovDeg: v)),
                          ),
                        ),
                      ],
                    ),
                    if (pose != null && calibTarget != null)
                      OutlinedButton.icon(
                        onPressed: () => _calibrate(pose, calibTarget),
                        icon: const Icon(Icons.center_focus_strong),
                        label: Text('Centre ${calibTarget.name} & calibrate'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.proj, this.snap, this.t);

  final SkyProjector proj;
  final SkySnapshot snap;
  final SkyTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    // Horizon line: sample azimuths at altitude 0.
    final horizon = Path();
    var started = false;
    for (var az = 0.0; az <= 360; az += 2) {
      final p = proj.project(Horizontal(az, 0));
      if (p == null) {
        started = false;
        continue;
      }
      started ? horizon.lineTo(p.dx, p.dy) : horizon.moveTo(p.dx, p.dy);
      started = true;
    }
    canvas.drawPath(
      horizon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = t.horizon,
    );

    for (final o in snap.objects) {
      if (o.kind == SkyObjectKind.star && o.magnitude > 3.0) continue;
      final p = proj.projectVisible(o.horizontal, margin: 20);
      if (p == null) continue;
      final color = colorForObject(o, t);
      final r = o.kind == SkyObjectKind.star
          ? (4 - o.magnitude).clamp(1.5, 5.0)
          : 7.0;
      canvas.drawCircle(
        p,
        r + 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.8),
      );
      if (o.kind != SkyObjectKind.star || o.magnitude < 2) {
        final tp = TextPainter(
          text: TextSpan(
            text: o.name,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p + Offset(r + 9, -8));
      }
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => true;
}
