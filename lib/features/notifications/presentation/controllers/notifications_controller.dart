import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';
import 'package:pcj_v5/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsController extends ChangeNotifier
    implements ValueListenable<int> {
  NotificationsController({required NotificationsRepository repository})
    : _repository = repository;

  final NotificationsRepository _repository;
  AsyncState<List<MemberNotification>> _state =
      const AsyncState<List<MemberNotification>>.initial();
  List<MemberNotification> _allNotifications = const <MemberNotification>[];
  bool _showAll = false;
  final Set<String> _markingReadIds = <String>{};
  bool _isMarkingAllRead = false;
  Object? _actionError;
  int _requestId = 0;

  AsyncState<List<MemberNotification>> get state => _state;
  bool get showAll => _showAll;
  bool get isMarkingAllRead => _isMarkingAllRead;
  Object? get actionError => _actionError;
  int get unreadCount => _allNotifications
      .where((MemberNotification notification) => !notification.isRead)
      .length;
  @override
  int get value => unreadCount;
  bool isMarkingRead(String id) =>
      _isMarkingAllRead || _markingReadIds.contains(id);

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;
    final int requestId = ++_requestId;
    _actionError = null;
    _state = AsyncState<List<MemberNotification>>.loading(
      previousData: _state.data,
    );
    notifyListeners();
    try {
      final List<MemberNotification> values =
          List<MemberNotification>.of(await _repository.getNotifications())
            ..sort((MemberNotification left, MemberNotification right) {
              return right.sentAt.compareTo(left.sentAt);
            });
      if (requestId != _requestId) return;
      _allNotifications = List<MemberNotification>.unmodifiable(values);
      _applyFilter();
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      _state = AsyncState<List<MemberNotification>>.failure(
        error,
        stackTrace,
        previousData: _state.data,
      );
    }
    if (requestId != _requestId) return;
    notifyListeners();
  }

  void showUnread() {
    if (!_showAll) return;
    _showAll = false;
    _applyFilter();
    notifyListeners();
  }

  void showAllNotifications() {
    if (_showAll) return;
    _showAll = true;
    _applyFilter();
    notifyListeners();
  }

  Future<void> markAsRead(MemberNotification notification) async {
    if (_isMarkingAllRead ||
        notification.isRead ||
        _markingReadIds.contains(notification.id)) {
      return;
    }
    _markingReadIds.add(notification.id);
    _actionError = null;
    notifyListeners();
    try {
      await _repository.markAsRead(notification.id);
      _allNotifications = _allNotifications
          .map(
            (MemberNotification value) => value.id == notification.id
                ? value.copyWith(isRead: true)
                : value,
          )
          .toList(growable: false);
      _applyFilter();
    } catch (error) {
      _actionError = error;
    } finally {
      _markingReadIds.remove(notification.id);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_isMarkingAllRead) return;
    final List<String> unreadIds = _allNotifications
        .where((MemberNotification value) => !value.isRead)
        .map((MemberNotification value) => value.id)
        .toList(growable: false);
    if (unreadIds.isEmpty) return;

    _isMarkingAllRead = true;
    _actionError = null;
    notifyListeners();

    final Set<String> completedIds = <String>{};
    try {
      for (final String id in unreadIds) {
        await _repository.markAsRead(id);
        completedIds.add(id);
      }
    } catch (error) {
      _actionError = error;
    } finally {
      if (completedIds.isNotEmpty) {
        _allNotifications = _allNotifications
            .map(
              (MemberNotification value) => completedIds.contains(value.id)
                  ? value.copyWith(isRead: true)
                  : value,
            )
            .toList(growable: false);
        _applyFilter();
      }
      _isMarkingAllRead = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    final List<MemberNotification> visible = _showAll
        ? _allNotifications
        : _allNotifications
              .where((MemberNotification value) => !value.isRead)
              .toList(growable: false);
    _state = AsyncState<List<MemberNotification>>.success(
      List<MemberNotification>.unmodifiable(visible),
    );
  }

  void reset() {
    _requestId++;
    _state = const AsyncState<List<MemberNotification>>.initial();
    _allNotifications = const <MemberNotification>[];
    _showAll = false;
    _markingReadIds.clear();
    _isMarkingAllRead = false;
    _actionError = null;
    notifyListeners();
  }
}
