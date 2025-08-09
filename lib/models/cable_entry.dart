import 'package:flutter/material.dart';

/// Represents a single cable entry for reconciliation.
class CableEntry {
  final String scbNo;
  final String icrNo;
  final String inverterNo;
  final double scheduledLength;
  String drumNo;
  double? startingReading;
  double? endReading;
  String? color; // NEW: Added a nullable String field for cable color

  CableEntry({
    required this.scbNo,
    required this.icrNo,
    required this.inverterNo,
    required this.scheduledLength,
    this.drumNo = '',
    this.startingReading,
    this.endReading,
    this.color, // NEW: Include in the constructor
  });

  // Factory constructor to create a CableEntry from a Firestore map
  factory CableEntry.fromMap(Map<String, dynamic> map) {
    return CableEntry(
      scbNo: map['scbNo'] as String,
      icrNo: map['icrNo'] as String,
      inverterNo: map['inverterNo'] as String,
      scheduledLength: (map['scheduledLength'] as num?)?.toDouble() ?? 0.0,
      drumNo: map['drumNo'] as String? ?? '',
      startingReading: (map['startingReading'] as num?)?.toDouble(),
      endReading: (map['endReading'] as num?)?.toDouble(),
      color: map['color'] as String?, // NEW: Extract 'color' from the map
    );
  }

  // Convert a CableEntry object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'scbNo': scbNo,
      'icrNo': icrNo,
      'inverterNo': inverterNo,
      'scheduledLength': scheduledLength,
      'drumNo': drumNo,
      'startingReading': startingReading,
      'endReading': endReading,
      'color': color, // NEW: Include 'color' in the map
    };
  }

  /// Computes the actual cut length: |Starting Reading - End Reading|.
  /// Returns 0.0 if either reading is null.
  double get actualCutLength {
    if (startingReading == null || endReading == null) {
      return 0.0;
    }
    return (startingReading! - endReading!).abs();
  }

  /// Computes the wastage: Actual Cut Length - Scheduled Length.
  double get wastage => actualCutLength - scheduledLength;

  /// Determines the color for displaying wastage based on its value.
  Color getWastageColor() {
    if (wastage > 0) {
      return Colors.green;
    } else if (wastage < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
