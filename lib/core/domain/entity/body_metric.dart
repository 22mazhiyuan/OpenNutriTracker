/// A body measurement tracked alongside weight.
///
/// Values are stored in one canonical unit: percent for [bodyFat],
/// centimetres for every circumference.
enum BodyMetric {
  bodyFat,
  waist,
  hip,
  chest,
  thigh,
  arm,
  calf;

  bool get isPercent => this == bodyFat;

  static BodyMetric? fromIndex(int index) {
    if (index < 0 || index >= values.length) return null;
    return values[index];
  }

  /// Whether [value] is a reading worth keeping. Zero and non-finite numbers
  /// are rejected; body fat above 100% and a circumference above 300 cm are
  /// treated as typos rather than data.
  bool accepts(double value) {
    if (!value.isFinite || value <= 0) return false;
    if (isPercent) return value <= 100;
    return value <= 300;
  }
}
