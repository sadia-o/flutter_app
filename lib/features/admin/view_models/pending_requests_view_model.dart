import 'package:flutter/foundation.dart';

import '../../../domain/models/access_request_failure.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/repositories/access_request_repository.dart';

enum PendingRequestsStatus { initial, loading, success, failure }

class PendingRequestsViewModel extends ChangeNotifier {
  PendingRequestsViewModel({
    required AccessRequestRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final AccessRequestRepository _repository;
  final DateTime Function() _now;

  PendingRequestsStatus _status = PendingRequestsStatus.initial;
  List<AccessRequestRecord> _requests = const [];
  String? _errorMessage;
  String? _refreshErrorMessage;
  int _refreshErrorEventId = 0;
  bool _isLoading = false;
  bool _isDisposed = false;
  bool _hasLoadedSuccessfully = false;

  PendingRequestsStatus get status => _status;
  List<AccessRequestRecord> get requests => _requests;
  String? get errorMessage => _errorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;
  int get refreshErrorEventId => _refreshErrorEventId;
  int get pendingCount => _requests.length;
  bool get isRefreshing =>
      _isLoading && _status == PendingRequestsStatus.success;

  int get newTodayCount {
    final today = _now();
    return _requests.where((record) {
      final submittedAt = record.submittedAt?.toLocal();
      return submittedAt != null &&
          submittedAt.year == today.year &&
          submittedAt.month == today.month &&
          submittedAt.day == today.day;
    }).length;
  }

  Future<void> load() => _fetch(isRefresh: false);

  Future<void> refresh() => _fetch(isRefresh: true);

  void removeReviewedRequest(String requestId) {
    if (!_requests.any((request) => request.id == requestId)) return;
    _requests = List.unmodifiable(
      _requests.where((request) => request.id != requestId),
    );
    _status = PendingRequestsStatus.success;
    _notifySafely();
  }

  Future<void> _fetch({required bool isRefresh}) async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    if (!isRefresh || !_hasLoadedSuccessfully) {
      _status = PendingRequestsStatus.loading;
      _errorMessage = null;
    }
    _notifySafely();

    try {
      final result = await _repository.getPendingRequests();
      if (_isDisposed) return;
      final sorted = result.toList()
        ..sort((left, right) {
          final leftTime = left.submittedAt;
          final rightTime = right.submittedAt;
          if (leftTime == null && rightTime == null) return 0;
          if (leftTime == null) return 1;
          if (rightTime == null) return -1;
          return rightTime.compareTo(leftTime);
        });
      _requests = List.unmodifiable(sorted);
      _status = PendingRequestsStatus.success;
      _errorMessage = null;
      _hasLoadedSuccessfully = true;
    } on AccessRequestFailure catch (failure) {
      if (_isDisposed) return;
      final message = _messageFor(failure.type);
      if (isRefresh && _hasLoadedSuccessfully) {
        _refreshErrorMessage = message;
        _refreshErrorEventId++;
      } else {
        _status = PendingRequestsStatus.failure;
        _errorMessage = message;
      }
    } catch (_) {
      if (_isDisposed) return;
      const message = 'Unable to load pending requests right now.';
      if (isRefresh && _hasLoadedSuccessfully) {
        _refreshErrorMessage = message;
        _refreshErrorEventId++;
      } else {
        _status = PendingRequestsStatus.failure;
        _errorMessage = message;
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  static String _messageFor(AccessRequestFailureType type) {
    return switch (type) {
      AccessRequestFailureType.permissionDenied =>
        'You do not have permission to review access requests.',
      AccessRequestFailureType.unauthenticated =>
        'Your session has expired. Please sign in again.',
      AccessRequestFailureType.unavailable ||
      AccessRequestFailureType.timeout =>
        'Unable to load pending requests. Check your connection and try again.',
      AccessRequestFailureType.missingIndex =>
        'Pending requests are temporarily unavailable while database setup is completed.',
      AccessRequestFailureType.invalidData =>
        'One or more access requests could not be loaded.',
      AccessRequestFailureType.notFound ||
      AccessRequestFailureType.alreadyReviewed ||
      AccessRequestFailureType.invalidRole ||
      AccessRequestFailureType.noFacilitySelected ||
      AccessRequestFailureType.duplicateApprovedInvitation =>
        'Unable to load pending requests right now.',
      AccessRequestFailureType.unknown =>
        'Unable to load pending requests right now.',
    };
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
