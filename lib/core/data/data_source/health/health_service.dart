import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';

/// The app's whole surface onto the platform health store — Health Connect
/// on Android, Apple Health on iOS.
///
/// Everything the `health` plugin can throw at us stops here: the plugin is
/// only ever touched by [HealthService] implementations, so the import
/// pipeline, its use case and its tests never load a method channel.
abstract class HealthService {
  /// Whether this device can serve health data at all — right platform, and
  /// on Android a Health Connect install that is actually usable.
  Future<bool> isAvailable();

  /// Asks the user for read access to workouts and body fat percentage.
  /// Returns whether the request came back granted.
  Future<bool> requestPermissions();

  /// Workout records overlapping `[from, to]`, oldest-first ordering not
  /// guaranteed. Throws if the platform refuses the read (revoked
  /// permission, Health Connect uninstalled) — callers decide whether that
  /// is a background hiccup to log or a failure to show the user.
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  });

  /// Most recent body fat percentage on record, as a percentage in 0..100.
  /// Null when nothing is recorded or the read was not permitted — the
  /// suggestion calculator treats that as "fall back to BMI".
  Future<double?> readLatestBodyFatPercent();

  /// Asks only for today's step count. Kept separate from [requestPermissions]
  /// so a declined step grant does not turn workout import off.
  Future<bool> requestStepPermission();

  /// Steps between local midnight and now. [StepReadResult.permitted] is
  /// false when the platform refused or has no health store — callers must
  /// not draw that as zero steps.
  Future<StepReadResult> readTodaySteps();
}

/// A step-count read. [steps] is meaningful only when [permitted] is true.
class StepReadResult {
  final bool permitted;
  final int steps;

  const StepReadResult({required this.permitted, required this.steps});

  static const unavailable = StepReadResult(permitted: false, steps: 0);
}
