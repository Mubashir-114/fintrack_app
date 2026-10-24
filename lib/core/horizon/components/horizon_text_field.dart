import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Cockpit input field for FinTrack // HORIZON.
/// Features 52px tactile height, Surface 1 fill, focus glow ring,
/// and optional currency prefix (`₹`).
class HorizonTextField extends StatefulWidget {
  const HorizonTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
    this.isCurrency = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final bool isCurrency;

  @override
  State<HorizonTextField> createState() => _HorizonTextFieldState();
}

class _HorizonTextFieldState extends State<HorizonTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant HorizonTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color borderColor;
    final List<BoxShadow> glowShadows;

    if (hasError) {
      borderColor = tokens.outflow;
      glowShadows = [
        BoxShadow(
          color: tokens.outflow.withValues(alpha: 0.20),
          blurRadius: 8,
        ),
      ];
    } else if (_isFocused) {
      borderColor = tokens.ionCyan;
      glowShadows = [
        BoxShadow(
          color: tokens.ionCyan.withValues(alpha: 0.25),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else {
      borderColor = tokens.rimNeutral;
      glowShadows = const [];
    }

    final currencyPrefix = widget.isCurrency ? '₹ ' : (widget.prefixText ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: HorizonTypography.labelCaps.copyWith(
              color: _isFocused ? tokens.ionCyan : tokens.textMedium,
              fontSize: 10,
              letterSpacing: 0.08 * 10,
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceSM),
        ],
        AnimatedContainer(
          duration: HorizonMotion.quick,
          constraints: const BoxConstraints(minHeight: HorizonDimensions.inputHeight),
          decoration: BoxDecoration(
            color: tokens.surface1,
            borderRadius: HorizonDimensions.borderDefault,
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: glowShadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _isFocused ? tokens.ionCyan : tokens.textLow,
                ),
                const SizedBox(width: HorizonDimensions.spaceSM),
              ],
              if (currencyPrefix.isNotEmpty)
                Text(
                  currencyPrefix,
                  style: HorizonTypography.headlineSm.copyWith(
                    color: _isFocused ? tokens.ionCyan : tokens.textLow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  autofillHints: widget.autofillHints,
                  obscureText: _obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: widget.validator,
                  style: widget.isCurrency
                      ? HorizonTypography.tabularAmountMd.copyWith(
                          color: tokens.textHigh,
                        )
                      : HorizonTypography.bodyMd.copyWith(
                          color: tokens.textHigh,
                        ),
                  cursorColor: tokens.ionCyan,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText,
                    errorMaxLines: 3,
                    labelText: widget.label,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintStyle: HorizonTypography.bodyMd.copyWith(
                      color: tokens.textLow,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                ),
              ),
              if (widget.suffixIcon != null)
                widget.suffixIcon!
              else if (widget.obscureText)
                IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: tokens.textLow,
                  ),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.outflow,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
