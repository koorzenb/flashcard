import 'package:flashcard/widgets/word_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../models/word.dart';
import '../storage/main_app_storage.dart';
import '../widgets/main_drawer.dart';
import '../widgets/version_code_text.dart';
import 'word_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MainAppStorage.box.displayedWelcomeScreen) {
        AppController.instance.showWelcomeScreen();
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
      body: Stack(
        children: [
          Center(
            child: WordList(),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: VersionCodeText(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await Get.to(() => WordDetailsScreen(
              title: 'Add Word',
              word: Word(
                native: '',
                pronunciation: '',
                translation: '',
                attributes: '',
                isNew: true,
              ),
            )),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      //   bottomNavigationBar: NavigationBar(destinations: [
      //   NavBarDestination(
      //     title: 'Writing',
      //     icon: Icons.create,
      //     onTap: () => Get.to(() => WritingScreen()),
      //   ),
      //   NavBarDestination(
      //     title: 'Reading',
      //     icon: Icons.abc_sharp,
      //     onTap: () => Get.to(() => ReadingScreen()),
      //   )
      // ]),
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
