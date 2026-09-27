import 'package:flutter/foundation.dart';

/// Shell-scoped controller that owns the currently selected facility (site ID)
/// for all authenticated tabs: Dashboard, Stations, Alerts, Reports.
///
/// Created once per authenticated shell route via ChangeNotifierProvider.
/// Disposed when the shell route is destroyed.
///
/// Constraints:
/// - Stores stable site IDs only (no Site objects, no repository calls).
/// - Rejects unauthorized site IDs silently (returns false from selectSite).
/// - Selects the first permitted site deterministically when no initialSiteId.
/// - Notifies listeners only when the selected site genuinely changes.
class ActiveFacilityController extends ChangeNotifier {
  final List<String> _permittedSiteIds;
  String? _selectedSiteId;

  ActiveFacilityController({
    required List<String> permittedSiteIds,
    String? initialSiteId,
  }) : _permittedSiteIds = List.unmodifiable(permittedSiteIds) {
    if (initialSiteId != null && permittedSiteIds.contains(initialSiteId)) {
      _selectedSiteId = initialSiteId;
    } else if (permittedSiteIds.isNotEmpty) {
      _selectedSiteId = permittedSiteIds.first;
    }
    // If permittedSiteIds is empty, _selectedSiteId remains null.
  }

  /// The immutable list of site IDs this user is permitted to access.
  List<String> get permittedSiteIds => _permittedSiteIds;

  /// The currently selected site ID. Null only when permittedSiteIds is empty.
  String? get selectedSiteId => _selectedSiteId;

  /// True when a site is selected.
  bool get hasSelectedSite => _selectedSiteId != null;

  /// Returns true when [siteId] is in the permitted list.
  bool isPermitted(String siteId) => _permittedSiteIds.contains(siteId);

  /// Selects [siteId] as the active facility.
  ///
  /// Returns true and notifies listeners only when the site is permitted
  /// and different from the currently selected site.
  /// Returns false without notifying when the site is unauthorized or unchanged.
  bool selectSite(String siteId) {
    if (!_permittedSiteIds.contains(siteId)) return false;
    if (_selectedSiteId == siteId) return false;
    _selectedSiteId = siteId;
    notifyListeners();
    return true;
  }

  void resetToInitialFacility() {
    final initialSiteId = _permittedSiteIds.isEmpty
        ? null
        : _permittedSiteIds.first;
    if (_selectedSiteId == initialSiteId) return;
    _selectedSiteId = initialSiteId;
    notifyListeners();
  }
}
