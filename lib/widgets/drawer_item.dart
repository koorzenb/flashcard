import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final void Function() onTap;

  const DrawerItem({required this.title, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: ListTile(
        title: Text(title),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      ),
    );
  }
}
