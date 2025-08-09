// lib/models/module_reconciliation.dart (NO CHANGE - already correct)
import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleReconciliation {
  final int totalInstalled; // Cumulative total of installed modules
  final int totalDamaged; // Cumulative total of damaged modules
  //final int totalScope; // to calculate the total scope
  final DateTime lastUpdated;

  ModuleReconciliation({
    required this.totalInstalled,
    required this.totalDamaged,
    //required this.totalScope,
    required this.lastUpdated,
  });

  // Factory constructor to create a ModuleReconciliation object from a Firestore map
  factory ModuleReconciliation.fromMap(Map<String, dynamic> map) {
    return ModuleReconciliation(
      totalInstalled: (map['totalInstalled'] as num?)?.toInt() ?? 0,
      totalDamaged: (map['totalDamaged'] as num?)?.toInt() ?? 0,
      //totalScope: (map['totalScope'] as num?)?.toInt() ??0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Method to convert a ModuleReconciliation object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'totalInstalled': totalInstalled,
      'totalDamaged': totalDamaged,
      ""
          'lastUpdated': Timestamp.fromDate(
        lastUpdated,
      ),
    };
  }
}
