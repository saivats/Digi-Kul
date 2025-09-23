import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:digikul_student_app/src/core/theme/app_colors.dart';

class LoadingButton extends StatelessWidget {

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
    this.isElevated = true,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: SpinKitRing(
              color: AppColors.textOnPrimary,
              size: 20,
              lineWidth: 2,
            ),
          )
        : child;

    if (isElevated) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      );
    } else {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      );
    }
  }
}

class LoadingTextButton extends StatelessWidget {

  const LoadingTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            height: 16,
            width: 16,
            child: SpinKitRing(
              color: AppColors.primary,
              size: 16,
              lineWidth: 2,
            ),
          )
        : child;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: buttonChild,
    );
  }
}

class LoadingIconButton extends StatelessWidget {

  const LoadingIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.iconSize,
    this.color,
    this.tooltip,
  });
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final double? iconSize;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconWidget = isLoading
        ? SizedBox(
            height: iconSize ?? 24,
            width: iconSize ?? 24,
            child: SpinKitRing(
              color: color ?? Theme.of(context).iconTheme.color ?? AppColors.primary,
              size: iconSize ?? 24,
              lineWidth: 2,
            ),
          )
        : Icon(
            icon,
            size: iconSize,
            color: color,
          );

    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: iconWidget,
      tooltip: tooltip,
    );
  }
}

class LoadingFloatingActionButton extends StatelessWidget {

  const LoadingFloatingActionButton({
    super.key,
    required this.onPressed,
    this.child,
    this.isLoading = false,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
  final VoidCallback? onPressed;
  final Widget? child;
  final bool isLoading;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SpinKitRing(
            color: AppColors.textOnPrimary,
            size: 24,
            lineWidth: 3,
          )
        : child ?? const Icon(Icons.add);

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: buttonChild,
    );
  }
}
