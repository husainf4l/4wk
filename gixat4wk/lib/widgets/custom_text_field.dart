import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final String? initialValue;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final FocusNode? focusNode;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final bool enableSuggestions;
  final bool autocorrect;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.validator,
    this.initialValue,
    this.isDense = false,
    this.contentPadding,
    this.filled = false,
    this.fillColor,
    this.focusNode,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: isDense,
        contentPadding: contentPadding,
        filled: filled,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withAlpha(128),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      focusNode: focusNode,
      enabled: enabled,
      textCapitalization: textCapitalization,
      onFieldSubmitted: onSubmitted,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
    );
  }

  // Factory for creating search fields
  factory CustomTextField.search({
    TextEditingController? controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon:
          controller != null && controller.text.isNotEmpty
              ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) onClear();
                },
              )
              : null,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.text,
      filled: true,
      focusNode: focusNode,
      isDense: true,
    );
  }

  // Factory for creating multiline text fields (notes, comments, etc.)
  factory CustomTextField.multiline({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? initialValue,
    int minLines = 3,
    int maxLines = 5,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      readOnly: readOnly,
      enabled: enabled,
    );
  }
}
