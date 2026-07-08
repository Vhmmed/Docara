import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const TermsCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xff8FBAC7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(
                color: Colors.grey[400]!,
                width: 2,
              ),
            ),
          ),
          const Gap(5),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  
                  color: Colors.grey[700],
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: ' Terms & Conditions ',
                    style: const TextStyle(
                      color: Color(0xff8FBAC7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: ' Privacy Policy',
                    style: const TextStyle(
                      color: Color(0xff8FBAC7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
