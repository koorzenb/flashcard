import 'attributes_migration.dart';
import 'migration.dart';

/// The registry of known migration steps.
///
/// **Every** schema change is added here as a new step - never as a new
/// subsystem. The steps are registered in ascending `fromVersion` order, but
/// the runner sorts them itself, so the registration order is only for
/// readability.
///
/// To add a step:
/// 1. Create a `Migration` subclass in this directory.
/// 2. Register it in [steps].
/// 3. Bump `AppConstants.currentWordSchemaVersion`.
///
/// Never renumber an existing step's id: the id is a stable identifier that
/// appears in logs and telemetry.
class MigrationRegistry {
  const MigrationRegistry._();

  /// The known steps.
  static const List<Migration> steps = <Migration>[AttributesMigration()];
}
