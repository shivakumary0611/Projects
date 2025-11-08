import 'package:basics/dice_roller.dart';
import 'package:flutter/material.dart';

class DiceRoll extends StatelessWidget {
  DiceRoll({super.key, required this.colors});

  final List<Color> colors;
  final startAlignment = Alignment.topLeft;
  final endAlignment = Alignment.bottomLeft;

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: startAlignment,
          end: endAlignment,
        ),
      ),
      child: Center(
        child: DiceRoller(),
      ),
    );
  }
}
