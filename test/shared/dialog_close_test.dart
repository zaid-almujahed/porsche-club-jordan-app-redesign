import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';

void main() {
  Future<void> openCodeDialog(
    WidgetTester tester, {
    DialogCloseWarning? warning,
    VoidCallback? onCancel,
  }) async {
    final TextEditingController code = TextEditingController();
    addTearDown(code.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext built) {
            context = built;
            return const Scaffold();
          },
        ),
      ),
    );
    unawaited(
      showOtpVerificationDialog(
        context: context,
        animation: code,
        email: 'member@example.com',
        otpController: code,
        onOtpChanged: (_) {},
        onVerify: () async => false,
        onResend: () async => false,
        isVerifying: () => false,
        isResending: () => false,
        errorText: () => null,
        instructions: 'Enter it below.',
        onCancel: onCancel,
        closeWarning: warning,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a code dialog that is safe to leave closes straight away', (
    WidgetTester tester,
  ) async {
    int cancels = 0;
    await openCodeDialog(tester, onCancel: () => cancels++);
    expect(find.text('Verify Your Email'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Email'), findsNothing);
    expect(cancels, 1);
  });

  testWidgets('leaving a guarded code dialog asks first', (
    WidgetTester tester,
  ) async {
    await openCodeDialog(
      tester,
      warning: const DialogCloseWarning(
        title: 'Leave without verifying?',
        message: 'Your application cannot be reviewed yet.',
      ),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without verifying?'), findsOneWidget);

    // Staying keeps the code dialog.
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Email'), findsOneWidget);

    // Back asks too; leaving closes it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave without verifying?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Email'), findsNothing);
  });
}
