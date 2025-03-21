import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

void main() {
  final pubspecFile = File('pubspec.yaml');
  final changelogFile = File('CHANGELOG.md');

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found!');
    return;
  }

  if (!changelogFile.existsSync()) {
    print('Error: CHANGELOG.md not found!');
    return;
  }

  // Read pubspec.yaml
  final pubspecContent = pubspecFile.readAsStringSync();
  final currentVersionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)\+(\d+)').firstMatch(pubspecContent);

  if (currentVersionMatch == null) {
    print('Error: Could not find version in pubspec.yaml!');
    return;
  }

  // Extract version and build number
  final currentVersion = Version.parse(currentVersionMatch.group(1)!); // Semantic version (e.g., 0.3.0)
  final currentBuildNumber = int.parse(currentVersionMatch.group(2)!); // Build number (e.g., 03000)

  // Get the current commit message from .git/COMMIT_EDITMSG
  final commitMessageFile = File('.git/COMMIT_EDITMSG');
  if (!commitMessageFile.existsSync()) {
    print('Error: Could not find .git/COMMIT_EDITMSG!');
    return;
  }

  final commitMessage = commitMessageFile.readAsStringSync().trim();

  if (commitMessage.isEmpty) {
    print('Error: Commit message is empty!');
    return;
  }

  // Extract commit type and description, with fallback if no type is present
  final commitParts = RegExp(r'^(.*?):\s*(.*)$').firstMatch(commitMessage);

  String commitType = 'Other'; // Default type if none is provided
  String commitDescription = commitMessage; // Use the entire message as description

  if (commitParts != null) {
    commitType = commitParts.group(1)!.trim().toLowerCase();
    commitDescription = commitParts.group(2)!.trim();
  }

  // Determine next version based on commit type
  Version nextVersion;
  int nextBuildNumber;
  if (commitType == 'fix' || commitType == 'bug' || commitType == 'ref') {
    nextVersion = currentVersion.nextPatch; // Increment the patch version
    nextBuildNumber = currentBuildNumber + 1; // Increment the build number
  } else {
    nextVersion = currentVersion.nextMinor; // Increment the minor version
    nextBuildNumber = currentBuildNumber + 100; // Increment the build number
  }

  // Update pubspec.yaml with new version and build number
  final updatedPubspecContent = pubspecContent.replaceFirst(
    RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'),
    'version: $nextVersion+$nextBuildNumber',
  );
  pubspecFile.writeAsStringSync(updatedPubspecContent);

  print('Updated pubspec.yaml to version: $nextVersion+$nextBuildNumber');

  // Update CHANGELOG.md
  final changelogEntry = '''
## $nextVersion

### ${capitalize(commitType == 'ref' ? 'refactor' : commitType)}

- $commitDescription

''';
  changelogFile.writeAsStringSync(changelogEntry + changelogFile.readAsStringSync());

  print('Added changelog entry for version: $nextVersion+$nextBuildNumber with type "$commitType" and message: "$commitDescription"');

  // Stage the updated files
  final gitAddResult = Process.runSync('git', ['add', 'pubspec.yaml', 'CHANGELOG.md']);
  if (gitAddResult.exitCode != 0) {
    print('Error: Failed to stage files. ${gitAddResult.stderr}');
    return;
  }

  print('Staged pubspec.yaml and CHANGELOG.md for commit.');
}

// Utility function to capitalize the first letter of a string
String capitalize(String input) {
  return input[0].toUpperCase() + input.substring(1);
}
