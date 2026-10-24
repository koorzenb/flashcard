import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

class AppConstants {
  static const String audioFileExtension = 'aac';

  static const Codec codec = Codec.aacADTS;

  /// The word data schema version this build understands.
  ///
  /// Every container (the local word box, the user's cloud word collection)
  /// records the version its data is actually at. The delta between the
  /// recorded version and this constant is the set of migration steps that
  /// still have to be applied.
  ///
  /// Bump this only together with a new registered step in
  /// `lib/logic/migrations/`.
  static const int currentWordSchemaVersion = 1;
}
