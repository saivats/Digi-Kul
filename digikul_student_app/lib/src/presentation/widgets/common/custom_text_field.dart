import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';
import 'package:digikul_student_app/src/core/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.fillColor,
    this.contentPadding,
  });
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? AppColors.textSecondary : AppColors.disabled,
              )
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? (enabled ? AppColors.surfaceVariant : AppColors.disabledBackground),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.disabled,
          ),
        ),
        labelStyle: enabled ? AppTextStyles.inputLabel : AppTextStyles.inputLabel.copyWith(
          color: AppColors.disabled,
        ),
        hintStyle: AppTextStyles.inputHint,
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.inputError,
        counterStyle: AppTextStyles.caption,
      ),
    );
  }
}

/// A specialized text field for search functionality
class SearchTextField extends StatelessWidget {

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty ?? false
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
    );
  }
}

/// A text field for numeric input
class NumericTextField extends StatelessWidget {

  const NumericTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.allowDecimals = false,
    this.allowNegative = false,
    this.min,
    this.max,
  });
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool allowDecimals;
  final bool allowNegative;
  final double? min;
  final double? max;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimals,
        signed: allowNegative,
      ),
      inputFormatters: [
        if (allowDecimals && allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
        else if (allowDecimals)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else if (allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        // Run custom validator first
        final customError = validator?.call(value);
        if (customError != null) return customError;

        if (value?.isNotEmpty ?? false) {
          final number = double.tryParse(value!);
          if (number == null) return 'Please enter a valid number';
          
          if (min != null && number < min!) {
            return 'Value must be at least $min';
          }
          
          if (max != null && number > max!) {
            return 'Value must be at most $max';
          }
        }
        
        return null;
      },
      onChanged: onChanged,
    );
  }
}
