import 'package:flutter/widgets.dart';

class AppConfig extends InheritedWidget {
  const AppConfig({
    Key? key,
    required this.appDisplayName,
    required this.appInternalId,
    required Widget child,
  }) : super(key: key, child: child);

  final String appDisplayName;
  final int appInternalId;

  static AppConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
