import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormattedNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? prefixText;
  final String? suffixText;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final String? obscuringCharacter;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const FormattedNumberInput({
    super.key,
    required this.controller,
    this.labelText,
    this.prefixText,
    this.suffixText,
    this.decoration,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<FormattedNumberInput> createState() => _FormattedNumberInputState();
}

class _FormattedNumberInputState extends State<FormattedNumberInput> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_formatAndDisplay);
    // Defer initial formatting to after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formatAndDisplay();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_formatAndDisplay);
    super.dispose();
  }

  void _formatAndDisplay() {
    if (_isUpdating || !mounted) return;

    final text = widget.controller.text;
    final formatted = _formatNumber(text);

    if (text != formatted) {
      _isUpdating = true;

      // Get current cursor position
      final cursorPos = widget.controller.selection.baseOffset;

      // Update text
      widget.controller.text = formatted;

      // Calculate new cursor position
      final commaCount = formatted.replaceAll(RegExp(r'[^,]'), '').length;
      final originalCommaCount = text.replaceAll(RegExp(r'[^,]'), '').length;
      final cursorAdjustment = commaCount - originalCommaCount;
      final newCursorPos = (cursorPos + cursorAdjustment).clamp(
        0,
        formatted.length,
      );

      // Set cursor position
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      );

      _isUpdating = false;
    }

    widget.onChanged?.call(_unformatNumber(formatted));
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';

    // Remove non-digit characters except decimal point
    String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');

    // Split into integer and decimal parts
    final parts = cleanValue.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Format integer part with commas
    if (integerPart.isNotEmpty) {
      final intVal = int.tryParse(integerPart) ?? 0;
      integerPart = intVal
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)},',
          );
    }

    return decimalPart.isNotEmpty ? '$integerPart.$decimalPart' : integerPart;
  }

  String _unformatNumber(String value) {
    if (value.isEmpty) return '';
    return value.replaceAll(RegExp(r'[^\d.]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            border: const OutlineInputBorder(),
          ),
      keyboardType:
          widget.keyboardType ??
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters:
          widget.inputFormatters ??
          [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.obscureText,
      obscuringCharacter: widget.obscuringCharacter ?? '•',
    );
  }
}
