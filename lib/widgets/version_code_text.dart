import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCodeText extends StatefulWidget {
  const VersionCodeText({Key? key}) : super(key: key);

  @override
  State<VersionCodeText> createState() => _VersionCodeTextState();
}

class _VersionCodeTextState extends State<VersionCodeText> {
  String versionCode = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) => setState(() => versionCode = packageInfo.version));
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '  $versionCode',
      style: const TextStyle(fontSize: 8.0, color: Colors.white10),
    );
  }
}
