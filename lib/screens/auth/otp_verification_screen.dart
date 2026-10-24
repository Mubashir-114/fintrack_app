import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/horizon/horizon.dart';
import '../analytics/widgets/fin_character.dart';

/// HORIZON verification preview. Email OTP is not supported by the backend;
/// this screen never accepts a code, sends a message or creates a session.
class OtpVerificationScreen extends StatelessWidget {
  final String? email;
  final String? destination;
  static const int _codeLength = 6;

  const OtpVerificationScreen({super.key, this.email, this.destination});

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.textHigh),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          "PROTOCOL VERIFICATION",
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textMedium,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.12 * 11,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Verification availability
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: HorizonDimensions.borderFull,
                      border: Border.all(
                        color: tokens.ionCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tokens.ionCyan,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tokens.ionCyan.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "EMAIL VERIFICATION UNAVAILABLE",
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.08 * 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Email verification",
                    style: HorizonTypography.headlineSm.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: tokens.textHigh,
                      letterSpacing: -0.02 * 24,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Email code verification is not available yet.\nSign in with your email and password.",
                    textAlign: TextAlign.center,
                    style: HorizonTypography.bodyMd.copyWith(
                      color: tokens.textMedium,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 6 Digit Segmented Input Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_codeLength, (index) {
                      return Expanded(
                        child: Container(
                          height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: HorizonDimensions.borderDefault,
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            key: ValueKey('otp_digit_$index'),
                            enabled: false,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: HorizonTypography.tabularAmountLg.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: tokens.textHigh,
                            ),
                            cursorColor: tokens.ionCyan,
                            decoration: const InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Verify CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: HorizonButton(
                      text: "BACK TO SIGN IN",
                      variant: HorizonButtonVariant.primary,
                      onPressed: () => context.go('/login'),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // FIN Sentinel Cameo in bottom right
            Positioned(
              bottom: 12,
              right: 12,
              child: Opacity(
                opacity: 0.9,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: tokens.surface2.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tokens.ionCyan.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.ionCyan.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const FinCharacter(size: 42),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
