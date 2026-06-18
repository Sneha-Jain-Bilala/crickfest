import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// A red error message that slides in from the top and disappears after 3 seconds.
// Shown when the server sends an error (e.g. "Room not found").
class ToastBanner extends StatelessWidget {
  final String message; // The error text to display

  const ToastBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Float at the top of the screen, centred
      top: 22,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF25150F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CrickifyColors.danger.withValues(alpha: 0.42),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x57000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: CrickifyTextStyles.button.copyWith(
              color: const Color(0xFFFFD8CA),
            ),
          ),
        ),
      ),
    );
  }
}
