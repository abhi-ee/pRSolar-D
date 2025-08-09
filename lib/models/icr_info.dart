// lib/models/icr_info.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IcrInfo {
  final int location;
  final String contact;
  final Map<String, int> gc1200;
  final Map<String, int> gc500;
  final int dummy;
  final String vendor;
  final DateTime createdAt;
  final String? icrDrawingUrl; // This field needs to be present

  IcrInfo({
    required this.location,
    required this.contact,
    required this.gc1200,
    required this.gc500,
    required this.dummy,
    required this.vendor,
    required this.createdAt,
    this.icrDrawingUrl, // And included in the constructor
  });

  // Factory constructor to create an IcrInfo from a Firestore document
  factory IcrInfo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return IcrInfo(
      location: data['location'] ?? 0,
      contact: data['contact'] ?? '',
      gc1200: Map<String, int>.from(data['gc1200'] ?? {}),
      gc500: Map<String, int>.from(data['gc500'] ?? {}),
      dummy: data['dummy'] ?? 0,
      vendor: data['vendor'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      icrDrawingUrl:
          data['icrDrawingUrl'], // Ensure this is parsed from Firestore
    );
  }

  // Method to convert IcrInfo object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'contact': contact,
      'gc1200': gc1200,
      'gc500': gc500,
      'dummy': dummy,
      'vendor': vendor,
      'createdAt': createdAt, // Or Timestamp.fromDate(createdAt)
      'icrDrawingUrl': icrDrawingUrl, // And included when converting to Map
    };
  }
}
