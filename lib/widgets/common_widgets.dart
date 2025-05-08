import 'package:flutter/material.dart';
import '../app_theme.dart';

class CommonWidgets {
  // App button with consistent styling
  static Widget appButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool isOutlined = false,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    final buttonStyle = isOutlined
        ? ElevatedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            side: BorderSide(color: AppTheme.primaryColor),
          )
        : ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          );

    Widget buttonContent = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Ensure content is centered
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis, // Handle text overflow gracefully
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonContent,
      ),
    );
  }

  // Card with consistent styling
  static Widget infoCard({
    required String title,
    required String subtitle,
    String? additionalInfo,
    IconData? icon,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: borderColor != null ? 2 : 0,
        ),
      ),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: AppTheme.primaryColor) : null,
        title: Text(title, style: AppTheme.subheadingStyle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: AppTheme.smallTextStyle),
            if (additionalInfo != null)
              Text(additionalInfo, style: AppTheme.smallTextStyle),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // Standard loading indicator
  static Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Error display widget
  static Widget errorDisplay({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.errorColor),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            appButton(
              text: 'Retry',
              onPressed: onRetry,
              backgroundColor: AppTheme.errorColor,
              icon: Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }

  // Empty state widget
  static Widget emptyState({
    required String message,
    IconData icon = Icons.hourglass_empty,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyTextStyle,
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            appButton(
              text: actionLabel,
              onPressed: onAction,
              isOutlined: true,
            ),
          ],
        ],
      ),
    );
  }

  // Standard app bar
  static AppBar standardAppBar({
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
    );
  }

  // Standard text field
  static Widget textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isMultiline = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
      ),
      validator: validator,
      keyboardType: keyboardType ?? (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? 5 : 1,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  // In-app notification banner
  static void showNotificationBanner(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        duration: duration,
      ),
    );
  }
}