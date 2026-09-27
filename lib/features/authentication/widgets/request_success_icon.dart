import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class RequestSuccessIcon extends StatelessWidget {
  const RequestSuccessIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: AppColors.greenTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.successGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2.5),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check,
            color: AppColors.surface,
            size: 24,
            semanticLabel: 'Request submitted successfully',
          ),
        ),
      ),
    );
  }
}
