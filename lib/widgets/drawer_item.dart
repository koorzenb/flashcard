import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final void Function() onTap;

  const DrawerItem({required this.title, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: onTap,
    );
  }
}
