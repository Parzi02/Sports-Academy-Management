import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon!,
            label: Text(text),
            style: ElevatedButton.styleFrom(
              minimumSize: fullWidth ? const Size(double.infinity, 52) : const Size(0, 52),
              padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: fullWidth ? const Size(double.infinity, 52) : const Size(0, 52),
              padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(text),
          );

    return button;
  }
}
