import 'package:flutter/material.dart';

class Style extends StatelessWidget {
  Style(this.text,{super.key});
String text;
  @override
  Widget build(context) {
    return Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: 28),
    );
  }
}
