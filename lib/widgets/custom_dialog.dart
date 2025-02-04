import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialog extends StatelessWidget {
  final String? _title;
  final String _confirmText;
  final String? cancelText;
  final void Function()? onConfirm;
  final void Function()? onCancel;
  final Widget? _content;
  final bool onWillPop;
  final bool autoClose;
  final Color backgroundColor;

  static Future<bool> showWelcomeMessage(
      {String? title,
      String text = '',
      String textConfirm = '',
      String? textCancel,
      Widget? content,
      bool autoClose = false,
      Color backgroundColor = Colors.white,
      bool barrierDismissible = true}) async {
    if (autoClose) {
      await Get.dialog(
        CustomDialog(
          title,
          textConfirm,
          content,
          backgroundColor: backgroundColor,
        ),
        barrierDismissible: barrierDismissible,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      return true;
    } else {
      final result = (await Get.dialog(
              CustomDialog(
                title,
                textConfirm,
                content,
                cancelText: textCancel,
              ),
              barrierDismissible: barrierDismissible)) ??
          false;

      return result;
    }
  }

  const CustomDialog(this._title, this._confirmText, this._content,
      {super.key,
      this.cancelText,
      this.onWillPop = true,
      this.autoClose = false,
      this.onConfirm,
      this.onCancel,
      this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    Widget? allContent;
    final contentFinal = _content; // To avoid ! operator
    allContent = SingleChildScrollView(
      child: contentFinal,
    );

    final title = _title;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 2.0,
          sigmaY: 2.0,
        ),
        child: AlertDialog(
            actionsPadding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
            elevation: 20.0,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () {
                    onCancel?.call();
                    Get.back(result: false);
                  },
                  child: Text(
                    cancelText ?? '',
                  ),
                ),
              TextButton(
                key: const Key('confirm_button'),
                onPressed: () {
                  onConfirm?.call();
                  Get.back(result: true);
                },
                child: Text(
                  _confirmText,
                ),
              ),
            ],
            backgroundColor: backgroundColor,
            contentPadding: const EdgeInsets.all(16.0),
            title: title != null
                ? Text(
                    title,
                    textAlign: TextAlign.center,
                  )
                : null,
            titlePadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            content: allContent),
      ),
    );
  }
}
