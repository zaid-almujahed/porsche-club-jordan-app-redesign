import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../widgets/application_status_page_widgets.dart';

class ApplicationStatusPage extends StatelessWidget {
  const ApplicationStatusPage({
    super.key,
    required this.user,
    required this.onContactSupport,
    required this.onContinue,
    required this.onLogOut,
    this.onEditProfile,
    this.onEditApplication,
  });

  final User user;
  final VoidCallback onContactSupport;
  final VoidCallback onContinue;
  final VoidCallback onLogOut;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditApplication;

  ApplicationStatus get _status => user.applicationStatus;

  Color get _statusColor {
    switch (_status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.denied:
        return AppColors.danger;
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.notSubmitted:
        return AppColors.textMuted;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.denied:
        return Icons.close_rounded;
      case ApplicationStatus.approved:
        return Icons.check_rounded;
      case ApplicationStatus.notSubmitted:
        return Icons.assignment_outlined;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.denied:
        return 'Denied';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.notSubmitted:
        return 'Not Submitted';
    }
  }

  List<String> get _paragraphs {
    switch (_status) {
      case ApplicationStatus.pending:
        return const <String>[
          'Your membership application has been received and is currently '
              'being reviewed by our committee.',
          'You will receive a response by email when the process is complete.',
        ];
      case ApplicationStatus.denied:
        return const <String>[
          'Thank you for your interest in our community.',
          'After a thorough review, we are unable to accept your application.',
          'While we understand this is disappointing news, our current '
              'membership criteria are not met at this time.',
        ];
      case ApplicationStatus.approved:
        return const <String>[
          'Congratulations! Your membership application has been approved '
              'by the committee.',
          'Please proceed to payment to finalize your membership.',
        ];
      case ApplicationStatus.notSubmitted:
        return const <String>[
          'Your membership application has not been submitted yet.',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Membership Application',
        showEdit:
            _status == ApplicationStatus.pending && onEditApplication != null,
        onEdit: onEditApplication,
      ),
      body: AppPageBody(
        topPadding: _status == ApplicationStatus.denied
            ? AppSpacing.section + AppSpacing.xl
            : AppSpacing.section,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ApplicationStatusPanel(
              icon: _statusIcon,
              iconColor: _statusColor,
              title: 'Application\n${_statusLabel.toUpperCase()}',
              paragraphs: _paragraphs,
            ),
            const SizedBox(height: AppSpacing.section),
            if (_status == ApplicationStatus.approved) ...<Widget>[
              PrimaryActionButton(
                label: 'Proceed to Payment',
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
                height: 58,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(
                label: 'Contact Support',
                onPressed: onContactSupport,
              ),
            ] else if (_status == ApplicationStatus.denied) ...<Widget>[
              PrimaryActionButton(label: 'Log Out', onPressed: onLogOut),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(
                label: 'Contact Support',
                onPressed: onContactSupport,
              ),
            ] else if (_status == ApplicationStatus.pending) ...<Widget>[
              PrimaryActionButton(
                label: 'Contact Support',
                onPressed: onContactSupport,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(label: 'Log Out', onPressed: onLogOut),
            ] else
              PrimaryActionButton(
                label: 'Continue Application',
                onPressed: onEditProfile,
              ),
          ],
        ),
      ),
    );
  }
}
