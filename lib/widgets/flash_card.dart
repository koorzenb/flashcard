import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';
import '../models/word.dart';

class FlashCardWidget extends StatefulWidget {
  final Word displayedWord;

  FlashCardWidget({required this.displayedWord, super.key});

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  AnimationStatus animationStatus = AnimationStatus.dismissed;
  static const progressIndicatorDuration = 4;
  static const opacityAnimationDuration = 2;
  bool showTranslation = false;
  bool enabledOnTap = true;
  bool startedOpacityAnimation = false;

  @override
  void initState() {
    _initAnimationController();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showProgressIndicator = animationStatus == AnimationStatus.forward;

    if (!showProgressIndicator) {
      _delayShowingTranslation();
    }

    return GetBuilder<WordController>(builder: (wordController) {
      return GestureDetector(
        onTap: () {
          if (animationStatus == AnimationStatus.forward || !enabledOnTap) {
            return;
          }

          setState(() {
            wordController.onTap();
            animationController.reset();
            animationController.forward();
            showTranslation = false;
            enabledOnTap = false;
            debugPrint('disabled');
          });
        },
        onLongPress: wordController.onLongPress,
        // TODO: need controller here to update word list after a deletion
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.displayedWord.hebrew,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Stack(children: [
                  // TODO: feature: scale by screenSize/cardSize -a Card doesn't have constrainst, so LayoutBuilder doesn't work here. At least check with GPT how a can get a sizebox to be a percentage of the current layout
                  Opacity(
                    opacity: showProgressIndicator ? 1 : 0.0,
                    child: SizedBox(
                      height: 48,
                      width: 48,
                      child: Center(
                        child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            value: animation.value,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue.shade300),
                            strokeWidth: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!showProgressIndicator)
                    AnimatedOpacity(
                        duration: showTranslation ? Duration(seconds: opacityAnimationDuration) : Duration.zero,
                        opacity: showTranslation ? 1.0 : 0.0,
                        child: Column(children: [
                          Text(
                            widget.displayedWord.pronunciation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            widget.displayedWord.translation,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
                          ),
                          widget.displayedWord.attributes.isNotEmpty
                              ? Text(
                                  widget.displayedWord.attributes,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                )
                              : SizedBox(height: 12),
                        ])),
                ]),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _initAnimationController() {
    animationController = AnimationController(
      duration: const Duration(seconds: progressIndicatorDuration),
      vsync: this,
    );

    animationController.addStatusListener((status) => setState(() => animationStatus = status));
    animation = Tween<double>(begin: 0, end: 1).animate(animationController)..addListener(() => setState(() {}));
    animationController.forward();
  }

  _delayShowingTranslation() {
    if (!showTranslation) {
      const startOpacityAnimationDelayMs = 100;
      Future.delayed(const Duration(milliseconds: startOpacityAnimationDelayMs), () => setState(() => showTranslation = true));
      Future.delayed(Duration(milliseconds: startOpacityAnimationDelayMs + (opacityAnimationDuration * 1000)), () => setState(() => enabledOnTap = true));
    }
  }
}

// TODO: change attributes to checkboxes: gender, plural, etc. Then color code the word. Will have to persist attribute settings too
// TODO: add ability to swop translation with hebrew word
