// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_app/models/cable_entry.dart';
import 'package:solar_app/models/mounting_progress_item.dart';
import 'package:solar_app/models/icr_info.dart';
import 'package:solar_app/models/quality_safety_item.dart';
import 'package:solar_app/constants/mms_material_quantities.dart'; // Ensure this is imported
import 'package:solar_app/constants/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:solar_app/models/module_reconciliation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get userId => _auth.currentUser?.uid;

  bool isDeveloper(String? uid) {
    if (uid == null) return false;
    return AppConstants.developerUids.contains(uid);
  }

  // --- Module Mounting Progress Items ---

  Stream<List<MountingProgressItem>> getMountingProgressItems() {
    if (userId == null) {
      print(
        'FirestoreService: getMountingProgressItems - userId is null. Returning empty stream.',
      );
      return Stream.value([]);
    }
    print('FirestoreService: Fetching mounting progress for user $userId');
    return _db
        .collection('users')
        .doc(userId)
        .collection('mountingProgress')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MountingProgressItem.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<MountingProgressItem?> getMountingProgressItemByName(
    String itemName,
  ) async {
    if (userId == null) {
      print(
        'FirestoreService: getMountingProgressItemByName - userId is null.',
      );
      return null;
    }
    try {
      final docSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('mountingProgress')
          .doc(itemName)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return MountingProgressItem.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print(
        'FirestoreService: Error getting mounting progress item "$itemName": $e',
      );
      return null;
    }
  }

  Future<void> saveMountingProgressItem(MountingProgressItem item) async {
    if (userId == null) {
      print(
        'FirestoreService: saveMountingProgressItem - User not authenticated. Cannot save mounting progress.',
      );
      return;
    }
    try {
      final itemToSave = MountingProgressItem(
        name: item.name,
        todayProgress: item.todayProgress,
        cumulativeProgress: item.cumulativeProgress,
        totalScope: item.totalScope, // Ensure totalScope is saved
        lastUpdated: DateTime.now(),
      );
      print(
        'FirestoreService: Saving mounting progress for ${itemToSave.name} to users/$userId/mountingProgress/${itemToSave.name} with timestamp ${itemToSave.lastUpdated}',
      );
      await _db
          .collection('users')
          .doc(userId)
          .collection('mountingProgress')
          .doc(itemToSave.name)
          .set(itemToSave.toMap());
      print(
        'FirestoreService: Mounting progress for ${itemToSave.name} saved successfully.',
      );
    } catch (e) {
      print(
        'FirestoreService: Error saving mounting progress for ${item.name}: $e',
      );
      throw e;
    }
  }

  Future<void> initializeDefaultMountingProgressItems() async {
    if (userId == null) return;

    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('mountingProgress');

    // Iterate through all defined MMS items and ensure they exist in Firestore
    for (var materialName in MmsMaterialQuantities.allMmsItems) {
      final doc = await collectionRef.doc(materialName).get();
      if (!doc.exists) {
        print(
          'FirestoreService: "$materialName" mounting progress item not found. Initializing default...',
        );
        final item = MountingProgressItem(
          name: materialName,
          todayProgress: 0.0,
          cumulativeProgress: 0.0,
          totalScope:
              0.0, // This will be updated by InfoScreen when ICR info is saved
          lastUpdated: DateTime.now(), // Initialize with current time
        );
        await collectionRef.doc(item.name).set(item.toMap());
        print(
          'FirestoreService: Default "$materialName" mounting progress item initialized.',
        );
      }
    }
    print(
      'FirestoreService: Default mounting progress items initialization checked/completed.',
    );
  }

  /// Initializes or updates the totalScope for all MMS items in Firestore.
  /// This method is typically called from InfoScreen after ICR info is saved.
  Future<void> initializeMountingProgressItemsWithScope(
    Map<String, double> calculatedScope,
  ) async {
    if (userId == null) return;

    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('mountingProgress');

    print(
      'FirestoreService: Initializing/Updating mounting progress items with calculated scope...',
    );
    final batch = _db.batch(); // Use a batch write for efficiency

    for (var materialName in MmsMaterialQuantities.allMmsItems) {
      final double totalScopeForMaterial = calculatedScope[materialName] ?? 0.0;
      final docRef = collectionRef.doc(materialName);

      // Get existing data to preserve todayProgress and cumulativeProgress
      final docSnapshot = await docRef.get();
      MountingProgressItem item;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        item = MountingProgressItem.fromMap(docSnapshot.data()!);
        item = MountingProgressItem(
          // Create a new instance to update immutable fields
          name: item.name,
          todayProgress: item.todayProgress,
          cumulativeProgress: item.cumulativeProgress,
          totalScope: totalScopeForMaterial, // Update scope
          lastUpdated: DateTime.now(), // Update timestamp
        );
        print(
          '  Updating existing item: ${item.name} with new totalScope: ${item.totalScope}',
        );
      } else {
        // If item doesn't exist, create it with default progress and new scope
        item = MountingProgressItem(
          name: materialName,
          todayProgress: 0.0,
          cumulativeProgress: 0.0,
          totalScope: totalScopeForMaterial,
          lastUpdated: DateTime.now(), // Initialize with current time
        );
        print(
          '  Creating new item: ${item.name} with totalScope: ${item.totalScope}',
        );
      }
      batch.set(docRef, item.toMap()); // Add to batch
    }
    await batch.commit(); // Commit all changes
    print(
      'FirestoreService: Mounting progress items initialized/updated with calculated scope.',
    );
  }

  // --- Module Reconciliation Specific Methods ---
  static const String _reconciliationDocId = 'reconciliation_data';

  Future<ModuleReconciliation> getModuleReconciliation() async {
    if (userId == null) {
      print(
        'FirestoreService: getModuleReconciliation - userId is null. Returning default.',
      );
      return ModuleReconciliation(
        totalInstalled: 0,
        totalDamaged: 0,
        lastUpdated: DateTime.now(),
      );
    }
    try {
      final docSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('moduleReconciliation')
          .doc(_reconciliationDocId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ModuleReconciliation.fromMap(docSnapshot.data()!);
      } else {
        final defaultData = ModuleReconciliation(
          totalInstalled: 0,
          totalDamaged: 0,
          lastUpdated: DateTime.now(),
        );
        await _db
            .collection('users')
            .doc(userId)
            .collection('moduleReconciliation')
            .doc(_reconciliationDocId)
            .set(defaultData.toMap());
        return defaultData;
      }
    } catch (e) {
      print('FirestoreService: Error getting module reconciliation data: $e');
      return ModuleReconciliation(
        totalInstalled: 0,
        totalDamaged: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> updateModuleReconciliation(ModuleReconciliation data) async {
    if (userId == null) {
      print(
        'FirestoreService: updateModuleReconciliation - User not authenticated. Cannot save.',
      );
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('moduleReconciliation')
          .doc(_reconciliationDocId)
          .set(data.toMap());
      print(
        'FirestoreService: Module reconciliation data updated successfully.',
      );
    } catch (e) {
      print('FirestoreService: Error updating module reconciliation data: $e');
      throw e;
    }
  }

  // --- Cable Entries ---

  Stream<List<CableEntry>> getCableEntries() {
    if (userId == null) {
      print(
        'FirestoreService: getCableEntries - userId is null. Returning empty stream.',
      );
      return Stream.value([]);
    }
    print('FirestoreService: Fetching cable entries for user $userId');
    return _db
        .collection('users')
        .doc(userId)
        .collection('cableEntries')
        .orderBy('scbNo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CableEntry.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveCableEntry(CableEntry entry) async {
    if (userId == null) {
      print(
        'FirestoreService: saveCableEntry - User not authenticated. Cannot save cable entry.',
      );
      return;
    }
    try {
      final entryToSave = CableEntry(
        scbNo: entry.scbNo,
        icrNo: entry.icrNo,
        inverterNo: entry.inverterNo,
        scheduledLength: entry.scheduledLength,
        drumNo: entry.drumNo,
        startingReading: entry.startingReading,
        endReading: entry.endReading,
        color: entry.color,
      );
      print(
        'FirestoreService: Saving cable entry for SCB ${entryToSave.scbNo} to users/$userId/cableEntries/${entryToSave.scbNo}',
      );
      await _db
          .collection('users')
          .doc(userId)
          .collection('cableEntries')
          .doc(entryToSave.scbNo)
          .collection('Colour')
          .doc(entryToSave.color)
          .set(entryToSave.toMap());
      print(
        'FirestoreService: Cable entry for SCB ${entryToSave.scbNo} saved successfully.',
      );
    } catch (e) {
      print(
        'FirestoreService: Error saving cable entry for SCB ${entry.scbNo}: $e',
      );
      throw e;
    }
  }

  Future<void> saveCableEntryBlack(CableEntry entry) async {
    if (userId == null) {
      print(
        'FirestoreService: saveCableEntry - User not authenticated. Cannot save cable entry.',
      );
      return;
    }
    try {
      final entryToSave = CableEntry(
        scbNo: entry.scbNo,
        icrNo: entry.icrNo,
        inverterNo: entry.inverterNo,
        scheduledLength: entry.scheduledLength,
        drumNo: entry.drumNo,
        startingReading: entry.startingReading,
        endReading: entry.endReading,
        color: entry.color,
      );
      print(
        'FirestoreService: Saving cable entry for SCB ${entryToSave.scbNo} to users/$userId/cableEntries/${entryToSave.scbNo}',
      );
      await _db
          .collection('users')
          .doc(userId)
          .collection('cableEntries')
          .doc(entryToSave.scbNo)
          .collection('Colour')
          .doc(entryToSave.color)
          .set(entryToSave.toMap());
      print(
        'FirestoreService: Cable entry for SCB ${entryToSave.scbNo} saved successfully.',
      );
    } catch (e) {
      print(
        'FirestoreService: Error saving cable entry for SCB ${entry.scbNo}: $e',
      );
      throw e;
    }
  }

  Future<void> initializeDefaultCableEntries(
    List<CableEntry> defaultEntries,
  ) async {
    if (userId == null) return;

    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('cableEntries');
    final querySnapshot = await collectionRef.limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      print(
        'FirestoreService: Cable entries collection is empty. Initializing default data...',
      );
      for (var entry in defaultEntries) {
        await collectionRef.doc(entry.scbNo).set(entry.toMap());
      }
      print('FirestoreService: Default cable entries initialized.');
    } else {
      print(
        'FirestoreService: Cable entries collection already contains data. Skipping initialization.',
      );
    }
  }

  Future<void> uploadCableScheduleFromCsv(
    List<CableEntry> entries,
    String fileName,
    Uint8List fileBytes,
  ) async {
    if (userId == null) {
      print(
        'FirestoreService: uploadCableScheduleFromCsv - User not authenticated.',
      );
      throw Exception('User not authenticated.');
    }

    try {
      final storageRef = _storage.ref().child(
        'users/$userId/cable_schedules/$fileName',
      );
      final uploadTask = storageRef.putData(fileBytes);
      await uploadTask.whenComplete(() => null);
      print(
        'FirestoreService: Cable schedule file "$fileName" uploaded to Storage.',
      );

      final collectionRef = _db
          .collection('users')
          .doc(userId)
          .collection('cableEntries');
      final batch = _db.batch();

      for (var entry in entries) {
        final docRef = collectionRef.doc(entry.scbNo);
        batch.set(docRef, entry.toMap());
      }

      await batch.commit();
      print(
        'FirestoreService: ${entries.length} cable entries saved to Firestore.',
      );
    } catch (e) {
      print('FirestoreService: Error uploading CSV or saving entries: $e');
      throw Exception('Failed to upload cable schedule: $e');
    }
  }

  // --- Quality & Safety Files ---

  Stream<List<QualitySafetyItem>> getQualitySafetyItems() {
    print(
      'FirestoreService: Fetching Quality & Safety items from qualitySafetyMetadata',
    );
    return _db
        .collection('qualitySafetyMetadata')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QualitySafetyItem.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> uploadQualitySafetyFile(PlatformFile platformFile) async {
    if (userId == null) {
      print(
        'FirestoreService: uploadQualitySafetyFile - User not authenticated.',
      );
      throw Exception('User not authenticated.');
    }
    if (!isDeveloper(userId)) {
      print(
        'FirestoreService: uploadQualitySafetyFile - User is not a developer. Access denied.',
      );
      throw Exception(
        'Permission denied: Only developers can upload Quality & Safety files.',
      );
    }

    final String fileName = platformFile.name;
    final Uint8List fileBytes = platformFile.bytes!;
    final String fileExtension = fileName.split('.').last.toLowerCase();

    String fileType;
    if (fileExtension == 'pdf') {
      fileType = 'pdf';
    } else if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
      fileType = 'image';
    } else {
      throw Exception(
        'Unsupported file type: Only PDF, JPG, JPEG, PNG are allowed.',
      );
    }

    try {
      final storageRef = _storage.ref().child(
        'quality_safety_files/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print(
        'FirestoreService: Quality & Safety file "$fileName" uploaded to Storage. URL: $downloadUrl',
      );

      final newDocRef = _db.collection('qualitySafetyMetadata').doc();
      final qualitySafetyItem = QualitySafetyItem(
        id: newDocRef.id,
        name: fileName,
        url: downloadUrl,
        type: fileType,
        uploadedAt: DateTime.now(),
        uploadedBy: userId!,
      );

      await newDocRef.set(qualitySafetyItem.toMap());
      print(
        'FirestoreService: Quality & Safety file metadata saved to Firestore with ID: ${newDocRef.id}',
      );
    } catch (e) {
      print(
        'FirestoreService: Error uploading Quality & Safety file or saving metadata: $e',
      );
      throw Exception(
        'Failed to upload Quality & Safety file: ${e.toString()}',
      );
    }
  }

  // --- ICR Information ---

  Future<void> saveIcrInfo(IcrInfo icrInfo) async {
    if (userId == null) {
      print(
        'FirestoreService: saveIcrInfo - User not authenticated. Cannot save ICR info.',
      );
      throw Exception('User not authenticated.');
    }
    try {
      final icrInfoToSave = IcrInfo(
        location: icrInfo.location,
        contact: icrInfo.contact,
        vendor: icrInfo.vendor,
        gc1200: icrInfo.gc1200,
        gc500: icrInfo.gc500,
        dummy: icrInfo.dummy,
        createdAt: DateTime.now(),
      );
      print(
        'FirestoreService: Saving ICR info for user $userId to users/$userId/icrInfo/user_icr_data with timestamp ${icrInfoToSave.createdAt}',
      );
      await _db
          .collection('users')
          .doc(userId)
          .collection('icrInfo')
          .doc('user_icr_data')
          .set(icrInfoToSave.toMap());
      print('FirestoreService: ICR info saved successfully for user $userId.');
    } catch (e) {
      print('FirestoreService: Error saving ICR info: $e');
      throw Exception('Failed to save ICR information: $e');
    }
  }

  Future<bool> doesIcrInfoExist(String userId) async {
    try {
      print(
        'FirestoreService: Checking if ICR info exists for user $userId at users/$userId/icrInfo/user_icr_data',
      );
      final docSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('icrInfo')
          .doc('user_icr_data')
          .get();
      print('FirestoreService: ICR info exists: ${docSnapshot.exists}');
      return docSnapshot.exists;
    } catch (e) {
      print('FirestoreService: Error checking if ICR info exists: $e');
      return false;
    }
  }

  Stream<IcrInfo?> getIcrInfo() {
    if (userId == null) {
      print(
        'FirestoreService: getIcrInfo - userId is null. Returning empty stream.',
      );
      return Stream.value(null);
    }
    print('FirestoreService: Fetching ICR info for user $userId');
    return _db
        .collection('users')
        .doc(userId)
        .collection('icrInfo')
        .doc('user_icr_data')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return IcrInfo.fromFirestore(snapshot);
          }
          return null;
        });
  }

  // NEW: Method to save the user's selected location to their profile
  Future<void> saveUserSelectedLocation(String userId, int location) async {
    try {
      await _db.collection('users').doc(userId).set({
        'selectedLocation': location,
      }, SetOptions(merge: true));
      print(
        'User selected location $location saved successfully for user $userId.',
      );
    } catch (e) {
      print('Error saving user selected location: $e');
      rethrow;
    }
  }

  // --- MMS Scope ---

  Future<void> saveMmsScope(Map<String, double> scopeData) async {
    if (userId == null) {
      print(
        'FirestoreService: saveMmsScope - User not authenticated. Cannot save MMS scope.',
      );
      throw Exception('User not authenticated.');
    }
    try {
      print(
        'FirestoreService: Saving MMS scope for user $userId to users/$userId/mmsScope/calculated_scope',
      );
      await _db
          .collection('users')
          .doc(userId)
          .collection('mmsScope')
          .doc('calculated_scope')
          .set(scopeData);
      print('FirestoreService: MMS scope saved successfully for user $userId.');
    } catch (e) {
      print('FirestoreService: Error saving MMS scope: $e');
      throw Exception('Failed to save MMS scope: $e');
    }
  }

  Stream<Map<String, double>> getMmsScope() {
    if (userId == null) {
      print(
        'FirestoreService: getMmsScope - userId is null. Returning empty stream.',
      );
      return Stream.value({});
    }
    print('FirestoreService: Fetching MMS scope for user $userId');
    return _db
        .collection('users')
        .doc(userId)
        .collection('mmsScope')
        .doc('calculated_scope')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return snapshot.data()!.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            );
          }
          return {};
        });
  }
}
