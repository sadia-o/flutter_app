import 'dashboard_species.dart';

class SpeciesBreakdownItem {
  final DashboardSpecies species;
  final int count;
  final double percentage;

  const SpeciesBreakdownItem({
    required this.species,
    required this.count,
    required this.percentage,
  });
}
