import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Subtitles extends StatelessWidget {
  const Subtitles({Key? key, required this.text}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
      top: 100,
    );
  }
}
