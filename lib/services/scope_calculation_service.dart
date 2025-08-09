// lib/services/scope_calculation_service.dart (NEW FILE)
import 'package:solar_app/constants/mms_material_quantities.dart';
import 'package:solar_app/models/icr_info.dart';

/// Service responsible for calculating the total scope of MMS materials.
class ScopeCalculationService {
  /// Calculates the total scope for each MMS material based on ICR information.
  /// Returns a map where the key is the material name and the value is its total scope.
  Map<String, double> calculateMmsScope(IcrInfo icrInfo) {
    final Map<String, double> totalScope = {};

    // Get total number of full and half tables from ICR info
    final int totalFullTables =
        icrInfo.gc1200['FullTable']! + icrInfo.gc500['FullTable']!;
    final int totalHalfTables =
        icrInfo.gc1200['HalfTable']! + icrInfo.gc500['HalfTable']!;

    print('ScopeCalculationService: Calculating scope with:');
    print('  Total Full Tables: $totalFullTables');
    print('  Total Half Tables: $totalHalfTables');

    // Calculate scope based on Full Tables
    MmsMaterialQuantities.fullTableQuantities.forEach((
      materialName,
      qtyPerTable,
    ) {
      totalScope[materialName] =
          (totalScope[materialName] ?? 0.0) +
          (qtyPerTable * totalFullTables).toDouble();
      print(
        '  Full Table - $materialName: $qtyPerTable * $totalFullTables = ${qtyPerTable * totalFullTables}',
      );
    });

    // Calculate scope based on Half Tables
    MmsMaterialQuantities.halfTableQuantities.forEach((
      materialName,
      qtyPerTable,
    ) {
      // Note: Purlin-4 and Purlin-5 are specific to half tables.
      // Other items like Rafter, Bracing, Strip are common and their quantities
      // are added to the existing totalScope for that material.
      totalScope[materialName] =
          (totalScope[materialName] ?? 0.0) +
          (qtyPerTable * totalHalfTables).toDouble();
      print(
        '  Half Table - $materialName: $qtyPerTable * $totalHalfTables = ${qtyPerTable * totalHalfTables}',
      );
    });

    print('ScopeCalculationService: Final calculated scope: $totalScope');
    return totalScope;
  }
}
