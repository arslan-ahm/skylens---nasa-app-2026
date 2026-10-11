import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:skylens/core/astro/astro_math.dart';
import 'package:skylens/core/astro/coordinates.dart';
import 'package:skylens/core/sensors/pointing_math.dart';

/// Sensor readings a device would report for a given attitude. The field
/// points north and down (northern hemisphere, ~60° dip).
({Vec3 g, Vec3 m}) readingsFor({
  required double cameraAz,
  required double cameraAlt,
}) {
  // Build device axes in world ENU: -z along the camera, +y "up-ish".
  final back = Horizontal(cameraAz, cameraAlt).toEnu(); // camera = -z
  final z = back * -1;
  final worldUp = const Vec3(0, 0, 1);
  var y = worldUp - z * worldUp.dot(z);
  if (y.length < 1e-6) {
    y = Horizontal(cameraAz, 0).toEnu(); // looking straight up/down
  }
  y = y.normalized();
  final x = y.cross(z);
  Vec3 toDevice(Vec3 w) => Vec3(x.dot(w), y.dot(w), z.dot(w));
  const field = Vec3(0, 20, -40); // µT, north + down
  return (g: toDevice(const Vec3(0, 0, 9.81)), m: toDevice(field));
}

void main() {
  test('camera direction recovers the simulated attitude', () {
    for (final (az, alt) in [
      (0.0, 0.0),
      (90.0, 30.0),
      (225.0, 45.0),
      (300.0, 80.0),
    ]) {
      final r = readingsFor(cameraAz: az, cameraAlt: alt);
      final pose = DevicePose.fromSensors(r.g, r.m)!;
      final dir = pose.cameraDirection;
      expect(dir.alt, closeTo(alt, 1e-6));
      expect(norm180(dir.az - az), closeTo(0, 1e-6), reason: 'az $az');
      expect(pose.rollDeg, closeTo(0, 1e-6));
    }
  });

  test('declination rotates azimuth', () {
    final r = readingsFor(cameraAz: 100, cameraAlt: 20);
    final pose = DevicePose.fromSensors(r.g, r.m, declinationDeg: 5)!;
    expect(pose.cameraDirection.az, closeTo(105, 1e-6));
  });

  test('projector puts the pointed-at direction at screen centre', () {
    final r = readingsFor(cameraAz: 150, cameraAlt: 40);
    final pose = DevicePose.fromSensors(r.g, r.m)!;
    final proj = SkyProjector(pose: pose, viewport: const Size(400, 800));

    final centre = proj.project(const Horizontal(150, 40))!;
    expect(centre.dx, closeTo(200, 1e-6));
    expect(centre.dy, closeTo(400, 1e-6));

    // Higher in the sky -> higher on screen; further east (larger az) -> right.
    expect(proj.project(const Horizontal(150, 50))!.dy, lessThan(400));
    expect(proj.project(const Horizontal(160, 40))!.dx, greaterThan(200));

    // Half the vertical FOV above centre lands on the top edge.
    expect(proj.project(const Horizontal(150, 70))!.dy, closeTo(0, 1e-6));

    // Directly behind the camera is not projectable.
    expect(proj.project(const Horizontal(330, -40)), isNull);
  });

  test('unproject inverts project', () {
    final r = readingsFor(cameraAz: 20, cameraAlt: 10);
    final proj = SkyProjector(
      pose: DevicePose.fromSensors(r.g, r.m)!,
      viewport: const Size(390, 844),
    );
    const target = Horizontal(32, 21);
    final back = proj.unproject(proj.project(target)!);
    expect(back.az, closeTo(target.az, 1e-6));
    expect(back.alt, closeTo(target.alt, 1e-6));
  });

  test('free fall yields no pose', () {
    expect(
      DevicePose.fromSensors(const Vec3(0, 0, 0.1), const Vec3(0, 20, -40)),
      isNull,
    );
  });

  test('calibration offset wraps around north', () {
    expect(calibrationOffset(measuredAz: 355, trueAz: 5), closeTo(10, 1e-9));
    expect(calibrationOffset(measuredAz: 5, trueAz: 355), closeTo(-10, 1e-9));
  });

  test('low-pass filter converges', () {
    final f = LowPassVec3(alpha: 0.5);
    f.add(const Vec3(0, 0, 0));
    for (var i = 0; i < 30; i++) {
      f.add(const Vec3(1, 2, 3));
    }
    expect(f.value!.x, closeTo(1, 1e-6));
  });
}
