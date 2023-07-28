import 'package:flashcard/screens/word_list_screen.dart';
import 'package:flashcard/widgets/drawer_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            color: Theme.of(context).colorScheme.primary,
            child: const Text(
              'Menu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const ListTile(),
          DrawerItem(
            title: "Word List",
            onTap: () => Get.to(() => const WordListScreen()),
          )
        ],
      ),
    );
  }
}
