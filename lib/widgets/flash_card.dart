import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/word_controller.dart';

class FlashCardWidget extends StatefulWidget {
  const FlashCardWidget({super.key});

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> with SingleTickerProviderStateMixin {
  bool isVisible = false;
  late AnimationController animationController;
  late Animation<double> animation;
  AnimationStatus animationStatus = AnimationStatus.dismissed;

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
    return GetBuilder<WordController>(builder: (flashCardController) {
      return GestureDetector(
        onTap: animationStatus == AnimationStatus.forward
            ? () {}
            : () {
                setState(() {
                  flashCardController.onTap();
                  animationController.reset();
                  animationController.forward();
                });
              },
        onLongPress: flashCardController.onLongPress,
        // TODO: need controller here to update word list after a deletion
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flashCardController.displayedWord.hebrew,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                animationStatus == AnimationStatus.forward
                    // TODO: feature: scale by screenSize/cardSize
                    ? SizedBox(
                        height: 48,
                        width: 48,
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              value: animation.value,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue.shade300),
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                      )
                    : Column(children: [
                        // TODO: feature: fade in translation instead of showing immediately
                        Text(
                          flashCardController.displayedWord.pronunciation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          flashCardController.displayedWord.translation,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
                        ),
                        flashCardController.displayedWord.attributes.isNotEmpty
                            ? Text(
                                flashCardController.displayedWord.attributes,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
                              )
                            : SizedBox(height: 12),
                      ])
              ],
            ),
          ),
        ),
      );
    });
  }

  void _initAnimationController() {
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animation = Tween<double>(begin: 0, end: 1).animate(animationController)..addListener(() => setState(() {}));
    animationController.addStatusListener((status) => animationStatus = status);
    animationController.forward();
  }
}
