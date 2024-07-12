import 'package:flashcard/screens/word_list_screen.dart';
import 'package:flashcard/widgets/drawer_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // TODO: make drawer button white
      // TODO: align drawer appbar with main app bar
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

          // gradle fix requires removal of flutter fire entries. I've done a flutter clean already and still the fix is required. Might as well start a new flutter project. Make an old directory of this, then create new project, copy git , install dependencies from scratch, then copy lib folder.

          // create a TODO - 'when done with this, ask ChatGPT to give Flutter implementation of design patterns'

          const SizedBox(
            height: 20,
          ),
          const ListTile(),
          DrawerItem(
            title: 'Word List',
            onTap: () => Get.to(() => const WordListScreen()),
          ),
        ],
      ),
    );
  }
}
