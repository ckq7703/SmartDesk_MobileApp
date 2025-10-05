import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import 'bottom_sheet_selector.dart';

class BottomSheetField extends StatelessWidget {
  final String label;
  final String value;
  final String valueText;
  final IconData icon;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Map<String, String> options;
  final bool showColorIndicator;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  const BottomSheetField({
    super.key,
    required this.label,
    required this.value,
    required this.valueText,
    required this.icon,
    this.leadingIcon,
    this.leadingIconColor,
    required this.options,
    this.showColorIndicator = true,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final result = await BottomSheetSelector.show(
                  context: context,
                  title: label,
                  selectedValue: value,
                  options: options,
                  icon: icon,
                  showColorIndicator: showColorIndicator,
                );

                if (result != null) {
                  onChanged(result);
                  state.didChange(result);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError
                        ? AppColors.error
                        : AppColors.borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (leadingIconColor ?? AppColors.primary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          leadingIcon,
                          size: 20,
                          color: leadingIconColor ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            valueText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
