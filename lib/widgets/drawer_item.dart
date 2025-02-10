import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final void Function() onTap;
  final IconData? icon;

  const DrawerItem({required this.title, required this.onTap, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      ),
    );
  }
}
