// lib/widgets/glass_card.dart
import 'package:flutter/material.dart';

/// A reusable Glassmorphism card widget for the MEDLINE Ultra-Modern theme.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final Color? highlightColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.opacity = 0.08,
    this.borderColor,
    this.boxShadow,
    this.onTap,
    this.isHighlighted = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHighlightColor = highlightColor ?? const Color(0xFF4DB6AC);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isHighlighted 
            ? effectiveHighlightColor.withOpacity(0.15)
            : Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isHighlighted 
              ? effectiveHighlightColor.withOpacity(0.5)
              : (borderColor ?? Colors.white.withOpacity(0.1)),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A glass-styled text field for forms
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;

  const GlassTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Colors.white70, size: 22)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

/// A glass-styled button
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isPrimary;
  final Color? color;
  final double? width;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isPrimary = true,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF4DB6AC);
    
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? effectiveColor 
              : Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary 
                ? BorderSide.none 
                : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          elevation: isPrimary ? 4 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A glass-styled dropdown
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hint;
  final IconData? prefixIcon;

  const GlassDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: Colors.white70, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                hint: hint != null 
                    ? Text(hint!, style: const TextStyle(color: Colors.white54))
                    : null,
                dropdownColor: const Color(0xFF1E2746),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                isExpanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
