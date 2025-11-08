import 'package:flutter/material.dart';
import 'dart:math';

final randomizer = Random();

class DiceRoll extends StatefulWidget {
  const DiceRoll({super.key});

  @override
  State<DiceRoll> createState() {
    return _DiceRoll();
  }
}

class _DiceRoll extends State<DiceRoll> {
  var activeImage = 'assets/images/dice-1.png';

  void rollDice() {
    setState(() {
      final id = randomizer.nextInt(6) + 1;
      activeImage = 'assets/images/dice-$id.png';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(activeImage, width: 200),
        const SizedBox(height: 10),
        TextButton(
          onPressed: rollDice,
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Roll Dice"),
        ),
      ],
    );
  }
}
