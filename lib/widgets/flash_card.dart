import 'package:flutter/material.dart';

import '../models/word.dart';

class FlashCard extends StatelessWidget {
  final Word word;

  const FlashCard({required this.word, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120, // TODO: fix to word width
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 20,
                    width: 30,
                    child: IconButton(
                        onPressed: () {},
                        iconSize: 10,
                        icon: const Icon(
                          Icons.edit,
                          size: 10,
                        )),
                  )
                ],
              ),
            ),
            Text(
              word.hebrew,
              style: const TextStyle(fontSize: 45, fontFamily: "Frank Ruhl Libre"),
            ),
            Text(
              word.pronunciation,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              word.translation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (word.attributes != null)
              Text(
                word.attributes!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
