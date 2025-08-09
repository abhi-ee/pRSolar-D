// lib/models/mounting_progress_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the progress data for a single item in the Module Mounting System.
class MountingProgressItem {
  final String name;
  double todayProgress;
  double cumulativeProgress;
  final double
  totalScope; // This will now be dynamically set from calculated scope
  final DateTime lastUpdated; // <--- This is the missing field!

  MountingProgressItem({
    required this.name,
    this.todayProgress = 0.0,
    this.cumulativeProgress = 0.0,
    this.totalScope =
        0.0, // Default to 0, will be updated from calculated scope
    required this.lastUpdated, // <--- It must be required in the constructor
  });

  // Factory constructor to create a MountingProgressItem from a Firestore map
  factory MountingProgressItem.fromMap(Map<String, dynamic> map) {
    return MountingProgressItem(
      name: map['name'] as String,
      todayProgress:
          (map['todayProgress'] as num?)?.toDouble() ?? 0.0, // Handle null
      cumulativeProgress:
          (map['cumulativeProgress'] as num?)?.toDouble() ?? 0.0, // Handle null
      totalScope: (map['totalScope'] as num?)?.toDouble() ?? 0.0, // Handle null
      lastUpdated: (map['lastUpdated'] as Timestamp)
          .toDate(), // <--- Convert Timestamp to DateTime
    );
  }

  // Convert a MountingProgressItem object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'todayProgress': todayProgress,
      'cumulativeProgress': cumulativeProgress,
      'totalScope': totalScope,
      'lastUpdated': Timestamp.fromDate(
        lastUpdated,
      ), // <--- Convert DateTime to Timestamp
    };
  }

  // Method to update cumulative progress based on today's input
  // Note: This method modifies the object's state. If you prefer immutability,
  // you'd return a new MountingProgressItem instance.
  void addTodayProgress() {
    // Ensure cumulative progress doesn't exceed total scope
    cumulativeProgress = (cumulativeProgress + todayProgress).clamp(
      0.0,
      totalScope,
    );
    todayProgress = 0.0; // Reset today's progress after adding
  }

  // Method to check if the item is completed
  bool get isCompleted => cumulativeProgress >= totalScope;

  // Optional: Add a copyWith method for immutability and easy updates
  MountingProgressItem copyWith({
    String? name,
    double? todayProgress,
    double? cumulativeProgress,
    double? totalScope,
    DateTime? lastUpdated,
  }) {
    return MountingProgressItem(
      name: name ?? this.name,
      todayProgress: todayProgress ?? this.todayProgress,
      cumulativeProgress: cumulativeProgress ?? this.cumulativeProgress,
      totalScope: totalScope ?? this.totalScope,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
