import 'package:flutter/material.dart';
import '../utils/config.dart';

class Button extends StatelessWidget {
  const Button(
      {Key? key,
        required this.width,
        required this.title,
        required this.onPressed,
        required this.disable,
        this.color = const Color(0xFFF8F7F2), // Default color
      })
      : super(key: key);

  final double width;
  final String title;
  final bool disable; //this is used to disable button
  final Function() onPressed;
  final Color color; // New color parameter

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8F7F2),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
          ),
        ),
        onPressed: disable ? null : onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}