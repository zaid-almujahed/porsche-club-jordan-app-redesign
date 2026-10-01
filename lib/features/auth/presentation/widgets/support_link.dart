import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/support_contact_sheet.dart';

import 'inline_link.dart';

/// "Need help? Contact Support", for pages where no one is signed in.
class SupportLink extends StatelessWidget {
  const SupportLink({
    super.key,
    this.senderEmail = '',
    this.initialTopic = 'Membership application',
  });

  final String senderEmail;
  final String initialTopic;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: <Widget>[
        Text(
          'Need help?',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        InlineLink(
          label: 'Contact Support',
          onPressed: () => showSupportContactSheet(
            context: context,
            senderEmail: senderEmail,
            initialTopic: initialTopic,
          ),
          textStyle: AppTextStyles.body.copyWith(
            color: AppColors.primaryBright,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
