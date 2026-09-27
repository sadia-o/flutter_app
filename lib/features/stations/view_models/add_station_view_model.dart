import 'package:flutter/foundation.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/repositories/station_repository.dart';
import '../../../domain/models/site.dart';
import '../../../app/state/active_facility_controller.dart';

class AddStationViewModel extends ChangeNotifier {
  final StationRepository _stationRepository;
  final ActiveFacilityController _activeFacilityController;
  final List<Site> _availableSites;

  AddStationViewModel({
    required StationRepository stationRepository,
    required ActiveFacilityController activeFacilityController,
    required List<Site> availableSites,
  }) : _stationRepository = stationRepository,
       _activeFacilityController = activeFacilityController,
       _availableSites = availableSites {
    _selectedSiteId = _activeFacilityController.selectedSiteId;
  }

  List<Site> get availableSites => _availableSites;

  // --- Form State ---

  String _stationId = '';
  String get stationId => _stationId;
  void setStationId(String value) {
    if (_stationId == value) return;
    _stationId = value;
    _validateForm();
  }

  String _stationName = '';
  String get stationName => _stationName;
  void setStationName(String value) {
    if (_stationName == value) return;
    _stationName = value;
    _validateForm();
  }

  String? _selectedSiteId;
  String? get selectedSiteId => _selectedSiteId;
  void setSelectedSiteId(String? value) {
    if (_selectedSiteId == value) return;
    _selectedSiteId = value;
    _validateForm();
    notifyListeners();
  }

  String _zoneLocation = '';
  String get zoneLocation => _zoneLocation;
  void setZoneLocation(String value) {
    if (_zoneLocation == value) return;
    _zoneLocation = value;
    _validateForm();
  }

  StationConnectivityType _connectivityType = StationConnectivityType.wifi;
  StationConnectivityType get connectivityType => _connectivityType;
  void setConnectivityType(StationConnectivityType type) {
    if (_connectivityType == type) return;
    _connectivityType = type;
    if (_connectivityType != StationConnectivityType.wifi) {
      _wifiNetworkName = null;
    }
    _validateForm();
    notifyListeners();
  }

  String? _wifiNetworkName;
  String? get wifiNetworkName => _wifiNetworkName;
  void setWifiNetworkName(String value) {
    if (_wifiNetworkName == value) return;
    _wifiNetworkName = value;
    _validateForm();
  }

  StationAlertPreferences _alertPreferences =
      StationAlertPreferences.defaults();
  StationAlertPreferences get alertPreferences => _alertPreferences;
  void setAlertPreferences(StationAlertPreferences prefs) {
    _alertPreferences = prefs;
    _validateForm();
    notifyListeners();
  }

  // --- Validation State ---

  bool _isValid = false;
  bool get isValid => _isValid;

  String? _stationIdError;
  String? get stationIdError => _stationIdError;

  String? _stationNameError;
  String? get stationNameError => _stationNameError;

  String? _siteIdError;
  String? get siteIdError => _siteIdError;

  String? _zoneLocationError;
  String? get zoneLocationError => _zoneLocationError;

  String? _wifiNetworkNameError;
  String? get wifiNetworkNameError => _wifiNetworkNameError;

  bool _hasAttemptedSubmit = false;

  void _validateForm() {
    _stationIdError = null;
    _stationNameError = null;
    _siteIdError = null;
    _zoneLocationError = null;
    _wifiNetworkNameError = null;
    _isValid = true;

    final trimmedId = _stationId.trim();
    if (trimmedId.isEmpty) {
      _stationIdError = 'Station ID is required.';
      _isValid = false;
    } else if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(trimmedId)) {
      _stationIdError = 'Enter a valid professional ID (e.g., RB-08).';
      _isValid = false;
    }

    if (_stationName.trim().isEmpty) {
      _stationNameError = 'Station Name is required.';
      _isValid = false;
    }

    if (_selectedSiteId == null || _selectedSiteId!.isEmpty) {
      _siteIdError = 'Site / Facility is required.';
      _isValid = false;
    } else if (!_availableSites.any((s) => s.id == _selectedSiteId)) {
      _siteIdError = 'Selected site is not authorized.';
      _isValid = false;
    }

    if (_zoneLocation.trim().isEmpty) {
      _zoneLocationError = 'Zone / Location is required.';
      _isValid = false;
    }

    if (_connectivityType == StationConnectivityType.wifi &&
        (_wifiNetworkName == null || _wifiNetworkName!.trim().isEmpty)) {
      _wifiNetworkNameError = 'Wi-Fi Network Name is required.';
      _isValid = false;
    }

    if (_hasAttemptedSubmit) {
      notifyListeners();
    }
  }

  // --- Submission State ---

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  int _submissionEventId = 0;
  int get submissionEventId => _submissionEventId;
  String? _submissionErrorMessage;
  String? get submissionErrorMessage => _submissionErrorMessage;
  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  Future<void> submit() async {
    _hasAttemptedSubmit = true;
    _validateForm();
    notifyListeners();

    if (!_isValid || _isSubmitting) return;

    _isSubmitting = true;
    _submissionErrorMessage = null;
    notifyListeners();

    try {
      final request = RegisterStationRequest(
        stationId: _stationId.trim(),
        stationName: _stationName.trim(),
        siteId: _selectedSiteId!,
        zoneLocation: _zoneLocation.trim(),
        connectivityType: _connectivityType,
        wifiNetworkName: _wifiNetworkName?.trim(),
        alertPreferences: _alertPreferences,
      );

      await _stationRepository.registerStation(request);
      _isSuccess = true;
      _submissionEventId++;
    } catch (e) {
      _submissionErrorMessage = e.toString().contains('already exists')
          ? 'Station with this ID already exists.'
          : 'Failed to register station.';
      _submissionEventId++;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
