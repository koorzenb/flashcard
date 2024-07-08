import 'dart:io';

class TestsHelper {
  // add helpers here

  static void deleteTestDataFolder(String kTestDataFolder) {
    final testFolder = Directory(kTestDataFolder);
    if (testFolder.existsSync()) {
      testFolder.deleteSync(recursive: true);
    }
  }
}
