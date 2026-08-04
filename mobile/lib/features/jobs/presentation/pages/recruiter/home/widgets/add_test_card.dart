import 'package:flutter/material.dart';

class AddTestCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddTestCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFD12E7D),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
