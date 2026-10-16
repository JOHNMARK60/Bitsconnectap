import 'package:flutter/material.dart';

class FaceCameraFrame extends StatelessWidget {
  const FaceCameraFrame({
    this.instruction = 'Place your face inside the frame',
    super.key,
  });

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            width: 245,
            height: 310,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(140),
              border: Border.all(color: const Color(0xFF2ED3A6), width: 5),
              color: const Color(0x3358D9E6),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}
