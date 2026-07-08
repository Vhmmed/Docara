import 'package:flutter/material.dart';
import '../../../../../widgets/loading/loading_widgets.dart';

class SubmitButton extends StatelessWidget {
  final bool submitting;
  final String label;
  final VoidCallback? onPressed;

  const SubmitButton({
    super.key,
    required this.submitting,
    this.label = 'Save',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: submitting ? null : onPressed,
      child: submitting
          ? const AppPulseDot(size: 20, color: Colors.white)
          : Text(label),
    );
  }
}
