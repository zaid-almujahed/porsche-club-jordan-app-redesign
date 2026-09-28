import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// Opens an in-app support message form and then hands the drafted message to
/// the device email application.
///
/// No support endpoint or approved support mailbox has been supplied yet.
/// Until it is, the member's email is deliberately used as the recipient.
Future<void> showSupportContactSheet({
  required BuildContext context,
  required String senderEmail,
  String initialTopic = 'Membership application',
}) async {
  final String email = senderEmail.trim();
  if (email.isEmpty) {
    showAppSnackBar(
      context,
      'No email address is available.',
      type: AppFeedbackType.warning,
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    // Above the whole app: opened from a tab it would otherwise sit under
    // the floating navigation bar, hiding the Open Email button.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panelDark,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        _SupportContactSheet(senderEmail: email, initialTopic: initialTopic),
  );
}

class _SupportContactSheet extends StatefulWidget {
  const _SupportContactSheet({
    required this.senderEmail,
    required this.initialTopic,
  });

  final String senderEmail;
  final String initialTopic;

  @override
  State<_SupportContactSheet> createState() => _SupportContactSheetState();
}

class _SupportContactSheetState extends State<_SupportContactSheet> {
  static const List<String> _topics = <String>[
    'Membership application',
    'Membership payment',
    'Account access',
    'Event registration',
    'Shop or order',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _bodyController;
  late String _topic = _topics.contains(widget.initialTopic)
      ? widget.initialTopic
      : _topics.first;
  bool _isOpeningMail = false;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _openMailComposer() async {
    if (!_formKey.currentState!.validate() || _isOpeningMail) return;

    setState(() => _isOpeningMail = true);
    final Uri message = Uri(
      scheme: 'mailto',
      path: widget.senderEmail,
      queryParameters: <String, String>{
        'subject': 'PCJ Support - $_topic',
        'body':
            '${_bodyController.text.trim()}\n\n'
            'Reply-to: ${widget.senderEmail}',
      },
    );

    bool opened = false;
    try {
      opened = await launchUrl(message, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;
    setState(() => _isOpeningMail = false);
    if (opened) {
      Navigator.of(context).pop();
      return;
    }

    showAppSnackBar(
      context,
      'No email app is available on this device.',
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: AppColors.panelDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x40FFFFFF),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    const AppIconBadge(icon: Icons.support_agent_rounded),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Contact Support',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 23,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isOpeningMail
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Tell us what you need and our team will reply by email.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('SUBJECT', style: AppTextStyles.overline),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: _topic,
                  // Long topics shorten with an ellipsis instead of
                  // overflowing on narrow screens / large text sizes.
                  isExpanded: true,
                  items: _topics
                      .map(
                        (String topic) => DropdownMenuItem<String>(
                          value: topic,
                          child: Text(
                            topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isOpeningMail
                      ? null
                      : (String? value) {
                          if (value != null) setState(() => _topic = value);
                        },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.topic_outlined, size: 20),
                  ),
                  style: AppTextStyles.input,
                  icon: const Icon(Icons.expand_more_rounded),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  dropdownColor: AppColors.surfaceRaised,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('MESSAGE', style: AppTextStyles.overline),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _bodyController,
                  enabled: !_isOpeningMail,
                  minLines: 5,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.input,
                  decoration: const InputDecoration(
                    hintText: 'Tell us how we can help.',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryActionButton(
                  label: 'Open Email',
                  icon: Icons.mail_outline_rounded,
                  onPressed: _isOpeningMail ? null : _openMailComposer,
                  isLoading: _isOpeningMail,
                  height: 56,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
