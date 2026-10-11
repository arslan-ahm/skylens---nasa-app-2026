import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../astro/astro_math.dart';
import '../astro/coordinates.dart';

/// Device attitude as a rotation from device axes to the local
/// East-North-Up frame, built from gravity + magnetic field vectors.
///
/// Device axes follow the Android convention (sensors_plus normalises iOS to
/// it): +x to the right of the screen, +y to the top of the screen, +z out of
/// the screen towards the user. The rear camera looks along -z.
class DevicePose {
  const DevicePose._(this.east, this.north, this.up);

  /// Rows of the rotation matrix: world axes expressed in device coordinates.
  final Vec3 east;
  final Vec3 north;
  final Vec3 up;

  /// Builds the pose like Android's `SensorManager.getRotationMatrix`.
  /// [gravity] is the accelerometer reading at rest (points up, away from the
  /// ground), [magnetic] the magnetometer reading. [declinationDeg] rotates
  /// magnetic north onto true north (east-positive). Returns null when the
  /// device is in free fall or near a strong magnetic disturbance.
  static DevicePose? fromSensors(
    Vec3 gravity,
    Vec3 magnetic, {
    double declinationDeg = 0,
  }) {
    final a = gravity.normalized();
    var h = magnetic.cross(gravity);
    if (h.length < 0.1 || gravity.length < 1) return null;
    h = h.normalized();
    final m = a.cross(h);
    final pose = DevicePose._(h, m, a);
    return declinationDeg == 0 ? pose : pose.rotatedAboutUp(declinationDeg);
  }

  /// Pose with yaw rotated by [deg] (positive = turn world frame clockwise
  /// seen from above). Used for declination and manual compass calibration.
  DevicePose rotatedAboutUp(double deg) {
    final c = cosD(deg), s = sinD(deg);
    // With east-positive declination, magnetic north lies east of true north,
    // so true north = magnetic north turned back (west) by [deg].
    return DevicePose._(east * c + north * s, north * c - east * s, up);
  }

  /// Device-frame vector -> world ENU.
  Vec3 toWorld(Vec3 d) => Vec3(east.dot(d), north.dot(d), up.dot(d));

  /// World ENU vector -> device frame (transpose of the rotation).
  Vec3 toDevice(Vec3 w) => east * w.x + north * w.y + up * w.z;

  /// Where the rear camera is pointing.
  Horizontal get cameraDirection =>
      Horizontal.fromEnu(toWorld(const Vec3(0, 0, -1)));

  /// Where the top edge of the phone is pointing (useful for flat "sky map"
  /// mode where the phone is held overhead like a planisphere).
  Horizontal get topEdgeDirection =>
      Horizontal.fromEnu(toWorld(const Vec3(0, 1, 0)));

  /// Camera roll in degrees (0 = upright portrait). Labels can counter-rotate
  /// by this so text stays level with the horizon.
  double get rollDeg {
    final upInDevice = toDevice(const Vec3(0, 0, 1));
    return atan2D(upInDevice.x, upInDevice.y);
  }
}

/// Projects sky directions onto the camera image (pinhole model).
class SkyProjector {
  const SkyProjector({
    required this.pose,
    required this.viewport,
    this.verticalFovDeg = 60,
  });

  final DevicePose pose;
  final Size viewport;

  /// Vertical field of view of the preview as displayed. Phone rear cameras
  /// are ~60–70° in portrait; calibrate per device if overlays drift.
  final double verticalFovDeg;

  double get _focalPx =>
      (viewport.height / 2) / math.tan(verticalFovDeg / 2 * deg2rad);

  /// Screen point for a direction, or null when it's behind the camera.
  Offset? project(Horizontal h) {
    final d = pose.toDevice(h.toEnu());
    if (d.z >= -1e-6) return null; // behind or exactly sideways
    final f = _focalPx;
    final x = viewport.width / 2 + f * d.x / -d.z;
    final y = viewport.height / 2 - f * d.y / -d.z;
    return Offset(x, y);
  }

  /// Like [project] but also requires the point to be on screen (with margin).
  Offset? projectVisible(Horizontal h, {double margin = 0}) {
    final p = project(h);
    if (p == null) return null;
    final inside =
        p.dx >= -margin &&
        p.dy >= -margin &&
        p.dx <= viewport.width + margin &&
        p.dy <= viewport.height + margin;
    return inside ? p : null;
  }

  /// Sky direction under a screen point — for tap-to-identify.
  Horizontal unproject(Offset p) {
    final f = _focalPx;
    final d = Vec3(
      (p.dx - viewport.width / 2) / f,
      -(p.dy - viewport.height / 2) / f,
      -1,
    );
    return Horizontal.fromEnu(pose.toWorld(d));
  }
}

/// Exponential low-pass filter for noisy sensor vectors.
class LowPassVec3 {
  LowPassVec3({this.alpha = 0.15});

  /// 0..1; lower = smoother but laggier.
  final double alpha;
  Vec3? _value;

  Vec3? get value => _value;

  Vec3 add(Vec3 sample) {
    final v = _value;
    _value = v == null ? sample : v + (sample - v) * alpha;
    return _value!;
  }

  void reset() => _value = null;
}

/// Compass offset that makes a measured azimuth match a known one — e.g. the
/// user centres the Moon on screen and taps "calibrate".
double calibrationOffset({
  required double measuredAz,
  required double trueAz,
}) => norm180(trueAz - measuredAz);
