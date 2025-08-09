import 'package:cloud_firestore/cloud_firestore.dart';

class QualitySafetyItem {
  final String id; // Document ID
  final String name; // File name, e.g., "Safety_Manual.pdf"
  final String url; // Download URL from Firebase Storage
  final String type; // 'pdf' or 'image'
  final DateTime uploadedAt;
  final String uploadedBy; // User ID of the uploader

  QualitySafetyItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory QualitySafetyItem.fromMap(Map<String, dynamic> map, String id) {
    return QualitySafetyItem(
      id: id,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }
}
