import 'dart:math' as math;

const double deg2rad = math.pi / 180;
const double rad2deg = 180 / math.pi;

double sinD(double deg) => math.sin(deg * deg2rad);
double cosD(double deg) => math.cos(deg * deg2rad);
double tanD(double deg) => math.tan(deg * deg2rad);
double asinD(double x) => math.asin(x.clamp(-1.0, 1.0)) * rad2deg;
double acosD(double x) => math.acos(x.clamp(-1.0, 1.0)) * rad2deg;
double atan2D(double y, double x) => math.atan2(y, x) * rad2deg;

/// Wraps an angle into [0, 360).
double norm360(double deg) {
  final r = deg % 360;
  return r < 0 ? r + 360 : r;
}

/// Wraps an angle into [-180, 180).
double norm180(double deg) {
  final r = norm360(deg + 180) - 180;
  return r;
}

/// A 3-vector used for rectangular coordinates and sensor math.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  @override
  String toString() =>
      'Vec3(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)}, ${z.toStringAsFixed(4)})';
}
