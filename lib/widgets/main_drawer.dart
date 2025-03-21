import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_settings.dart';
import '../screens/word_list_screen.dart';
import '../services/flashcard_auth_service.dart';
import 'drawer_item.dart';

class MainDrawer extends StatelessWidget {
  MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Menu',
                        style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.all(0),
                ),
                const SizedBox(
                  height: 20,
                ),
                DrawerItem(
                  icon: Icons.list,
                  title: 'Word List',
                  onTap: () => Get.to(() => WordListScreen()),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Divider(),
              DrawerItem(
                  title: 'Sign Out',
                  onTap: () {
                    FlashcardAuthService.signOut();
                    clearAppData();
                  },
                  icon: Icons.logout),
            ],
          )
        ],
      ),
    );
  }
}
