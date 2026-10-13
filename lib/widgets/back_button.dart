import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const AppBackButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 21,
          color: Color(0xFF5F5A78),
        ),
      ),
    );
  }
}