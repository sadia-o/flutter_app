import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/auth_session_coordinator.dart';

class SplashViewModel extends ChangeNotifier {
  final AuthSessionCoordinator _sessionCoordinator;

  SplashViewModel(this._sessionCoordinator);

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;
  Timer? _timer;
  bool _minimumDurationElapsed = false;

  void initialize(Duration splashDuration) {
    // Prevent multiple initializations
    if (_timer != null || _isCompleted) return;

    _sessionCoordinator.addListener(_tryComplete);
    _timer = Timer(splashDuration, () {
      _minimumDurationElapsed = true;
      _tryComplete();
    });
    _tryComplete();
  }

  void _tryComplete() {
    if (_isCompleted ||
        !_minimumDurationElapsed ||
        !_sessionCoordinator.restorationComplete) {
      return;
    }
    _isCompleted = true;
    _sessionCoordinator.removeListener(_tryComplete);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionCoordinator.removeListener(_tryComplete);
    super.dispose();
  }
}
