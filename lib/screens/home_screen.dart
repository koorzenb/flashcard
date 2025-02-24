import 'package:flashcard/screens/reading_screen.dart';
import 'package:flashcard/screens/writing_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/flash_card_app_controller.dart';
import '../storage/main_app_storage.dart';
import '../widgets/main_drawer.dart';
import '../widgets/version_code_text.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MainAppStorage.box.displayedWelcomeScreen) {
        FlashcardAppController.getOrPut.showWelcomeScreen();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            VersionCodeText(),
          ],
        ),
      ),
      drawer: MainDrawer(),
      body: NavigationBar(destinations: [
        NavBarDestination(
          title: 'Writing',
          icon: Icons.create,
          onTap: () => Get.to(() => WritingScreen()),
        ),
        NavBarDestination(
          title: 'Reading',
          icon: Icons.abc_sharp,
          onTap: () => Get.to(() => ReadingScreen()),
        )
      ]),
    );
  }
}

class NavBarDestination extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function() onTap;

  NavBarDestination({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
