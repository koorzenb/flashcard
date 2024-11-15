import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../controllers/flash_card_app_controller.dart';
import '../controllers/word_controller.dart';
import '../models/word.dart';
import '../widgets/flash_card.dart';
import '../widgets/main_drawer.dart';
import '../widgets/version_code_text.dart';
import 'word_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({
    required this.title,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TutorialCoachMark tutorialCoachMark;

  coach mark appear in main screen, but not wrapping the flash card widget correctly - too large

  @override
  void initState() {
    createTutorial();
    Future.delayed(Duration(seconds: 10), showTutorial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FlashCardAppController.getOrPut.showWelcomeScreen();
      }
    });
    super.initState();
  }

  final flashCardController = WordController.getOrPut;
  final flashCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(width: 10.0),
            VersionCodeText(),
          ],
        ),
      ),
      drawer: MainDrawer(),
      body: Center(
        key: flashCardKey,
        child: FlashCardWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await Get.to(() => WordDetailsScreen(
              title: 'Add Word',
              word: Word(
                hebrew: '',
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
    );
  }

  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.red,
      textSkip: 'SKIP',
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        print('finish');
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print('target: $target');
        print('clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}');
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
      onSkip: () {
        print('skip');
        return true;
      },
    );
  }

  void showTutorial() {
    tutorialCoachMark.show(context: context);
  }

  //  mark is showing but too wide. research into smaller
//
  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: 'flashCardKey',
        keyTarget: flashCardKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Titulo lorem ipsum',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }
}
