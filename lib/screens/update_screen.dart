import 'package:flutter/material.dart';

class UpdateScreen extends StatefulWidget {
  //TODO: stateful required?

  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _form = GlobalKey<FormState>();
  final _hebrewTextController = TextEditingController();
  final _pronunciationTextController = TextEditingController();
  final _translationTextController = TextEditingController();
  final _attributesTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _hebrewTextController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.abc),
                  hintText: 'What is the Hebrew word?',
                  labelText: 'Hebrew',
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (String? _) {
                  return _hebrewTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
                },
              ),
              TextFormField(
                controller: _pronunciationTextController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.abc),
                  hintText: 'How would this word phonetically be pronounced?',
                  labelText: 'Pronunciation',
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (String? _) {
                  return _pronunciationTextController.text.trim().isEmpty ? 'Please enter valid pronunciation' : null;
                },
              ),
              TextFormField(
                controller: _translationTextController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.abc),
                  hintText: 'What does this word translate to in English?',
                  labelText: 'English',
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (String? _) {
                  return _hebrewTextController.text.trim().isEmpty ? 'Please enter valid word' : null;
                },
              ),
              TextFormField(
                controller: _attributesTextController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.abc),
                  hintText: 'What type of word is this? (hint: gender, grammatical type, etc.)',
                  labelText: 'Attributes',
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ],
          )),
    );
  }
}
