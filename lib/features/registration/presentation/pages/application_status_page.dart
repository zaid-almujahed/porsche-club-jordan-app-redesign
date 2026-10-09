import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../widgets/application_status_page_widgets.dart';

class ApplicationStatusPage extends StatefulWidget {
  const ApplicationStatusPage({
    super.key,
    required this.user,
    required this.onContactSupport,
    required this.onContinue,
    required this.onLogOut,
    this.onEditProfile,
    this.onEditApplication,
    this.onRecheck,
    this.onApproved,
  });

  final User user;
  final VoidCallback onContactSupport;
  final VoidCallback onContinue;
  final VoidCallback onLogOut;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditApplication;

  /// Asks the backend again for a pending application's decision; null when
  /// there is no answer.
  final Future<ApplicationStatus?> Function()? onRecheck;

  /// The application was approved while this page was open: leads on to
  /// signing in and paying.
  final VoidCallback? onApproved;

  /// How often a pending application is checked while the page is open:
  /// every 10 seconds, like the app's other live updates. Each check is a
  /// password sign in on the server, so not more often.
  static const Duration recheckInterval = Duration(seconds: 10);

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage>
    with WidgetsBindingObserver {
  late ApplicationStatus _status = widget.user.applicationStatus;
  Timer? _timer;
  bool _isChecking = false;

  bool get _canRecheck =>
      widget.onRecheck != null && _status == ApplicationStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_canRecheck) {
      _timer = Timer.periodic(
        ApplicationStatusPage.recheckInterval,
        (_) => _recheck(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _recheck() async {
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!_canRecheck ||
        _isChecking ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    _isChecking = true;
    final ApplicationStatus? status = await widget.onRecheck!();
    _isChecking = false;
    if (!mounted || status == null || status == _status) return;
    _timer?.cancel();
    setState(() => _status = status);
    if (status == ApplicationStatus.approved) widget.onApproved?.call();
  }

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
        return 'Rejected';
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
      extendBodyBehindAppBar: true,
      appBar: PorscheAppBar(
        title: 'Membership Application',
        showEdit:
            _status == ApplicationStatus.pending &&
            widget.onEditApplication != null,
        onEdit: widget.onEditApplication,
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
                label: widget.onApproved == null
                    ? 'Proceed to Payment'
                    : 'Continue',
                onPressed: widget.onApproved ?? widget.onContinue,
                height: 58,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(
                label: 'Contact Support',
                onPressed: widget.onContactSupport,
              ),
            ] else if (_status == ApplicationStatus.denied) ...<Widget>[
              PrimaryActionButton(label: 'Log Out', onPressed: widget.onLogOut),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(
                label: 'Contact Support',
                onPressed: widget.onContactSupport,
              ),
            ] else if (_status == ApplicationStatus.pending) ...<Widget>[
              PrimaryActionButton(
                label: 'Contact Support',
                onPressed: widget.onContactSupport,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryActionButton(
                label: 'Log Out',
                onPressed: widget.onLogOut,
              ),
            ] else
              PrimaryActionButton(
                label: 'Continue Application',
                onPressed: widget.onEditProfile,
              ),
          ],
        ),
      ),
    );
  }
}
