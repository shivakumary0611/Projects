import 'package:basics/dice_roll.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blue,
        body: DiceRoll(colors: [Colors.blue, Colors.green]),
      ),
    ),
  );
}
