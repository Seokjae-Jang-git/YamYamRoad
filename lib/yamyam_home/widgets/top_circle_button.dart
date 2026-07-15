import 'package:flutter/material.dart';

class TopCircleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const TopCircleButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, height: 1.2),
        ),
      ),
    );
  }
}