import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../astro/astro_math.dart';
import 'pointing_math.dart';

/// Fuses accelerometer + magnetometer into a smoothed [DevicePose] stream.
///
/// Limitations to keep in mind (and to tell users):
/// - Magnetometers are disturbed by metal, cars, cases with magnets.
/// - Azimuth is magnetic unless [declinationDeg] / calibration is applied.
/// - Browsers generally don't expose a magnetometer, so on web this stream
///   emits nothing — use the manual drag-to-pan sky map there.
class OrientationService {
  OrientationService({this.alpha = 0.12});

  /// Low-pass factor; lower = steadier but laggier overlays.
  final double alpha;

  Stream<DevicePose> poses({
    double declinationDeg = 0,
    Duration samplingPeriod = SensorInterval.gameInterval,
  }) {
    late StreamController<DevicePose> controller;
    StreamSubscription<AccelerometerEvent>? accSub;
    StreamSubscription<MagnetometerEvent>? magSub;
    final grav = LowPassVec3(alpha: alpha);
    final mag = LowPassVec3(alpha: alpha);

    void emit() {
      final g = grav.value, m = mag.value;
      if (g == null || m == null) return;
      final pose = DevicePose.fromSensors(g, m, declinationDeg: declinationDeg);
      if (pose != null && !controller.isClosed) controller.add(pose);
    }

    controller = StreamController<DevicePose>(
      onListen: () {
        accSub = accelerometerEventStream(samplingPeriod: samplingPeriod)
            .listen((e) {
              grav.add(Vec3(e.x, e.y, e.z));
              emit();
            }, onError: (Object e) => debugPrint('accelerometer: $e'));
        magSub = magnetometerEventStream(samplingPeriod: samplingPeriod).listen(
          (e) => mag.add(Vec3(e.x, e.y, e.z)),
          onError: (Object e) => debugPrint('magnetometer: $e'),
        );
      },
      onCancel: () async {
        await accSub?.cancel();
        await magSub?.cancel();
      },
    );
    return controller.stream;
  }
}
