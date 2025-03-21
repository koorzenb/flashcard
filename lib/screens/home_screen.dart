import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/flash_card_app_controller.dart';
import '../storage/main_app_storage.dart';
import '../widgets/main_drawer.dart';
import '../widgets/version_code_text.dart';
import 'reading_screen.dart';
import 'writing_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MainAppStorage.box.displayedWelcomeScreen) {
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
      ),
      drawer: MainDrawer(),
      bottomNavigationBar: NavigationBar(destinations: [
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
      body: Stack(
        children: [
          // ...existing body content...
          Positioned(
            bottom: 16,
            left: 16,
            child: VersionCodeText(),
          ),
        ],
      ),
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
