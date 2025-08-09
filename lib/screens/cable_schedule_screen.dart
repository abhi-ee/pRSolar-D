// lib/screens/cable_schedule_screen.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:solar_app/models/cable_entry.dart';
import 'package:solar_app/widgets/cable_reconciliation_card.dart';
import 'package:solar_app/widgets/cable_summary_widget.dart';
import 'package:solar_app/services/firestore_service.dart';
import 'dart:async';

class CableScheduleScreen extends StatefulWidget {
  const CableScheduleScreen({super.key});

  @override
  State<CableScheduleScreen> createState() => _CableScheduleScreenState();
}

class _CableScheduleScreenState extends State<CableScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<CableEntry>>? _cableEntriesSubscription;

  final List<CableEntry> _defaultCableEntries = [
    CableEntry(
      scbNo: "801",
      icrNo: "ICR-33",
      inverterNo: "INV.-02",
      scheduledLength: 656,
      color: 'Red', // Default color for this entry
    ),
  ];

  Map<String, CableEntry> _liveCableEntriesMap = {};

  final Map<String, TextEditingController> _drumNoControllers = {};
  final Map<String, TextEditingController> _startingReadingControllers = {};
  final Map<String, TextEditingController> _endReadingControllers = {};

  @override
  void initState() {
    super.initState();
    _firestoreService.initializeDefaultCableEntries(_defaultCableEntries);

    _cableEntriesSubscription = _firestoreService.getCableEntries().listen((
      entries,
    ) {
      setState(() {
        final newLiveMap = <String, CableEntry>{};
        for (var entry in entries) {
          // Get or create controllers for this entry
          final drumController = _drumNoControllers.putIfAbsent(
            entry.scbNo,
            () => TextEditingController(),
          );
          final startController = _startingReadingControllers.putIfAbsent(
            entry.scbNo,
            () => TextEditingController(),
          );
          final endController = _endReadingControllers.putIfAbsent(
            entry.scbNo,
            () => TextEditingController(),
          );

          // Use the entry directly from Firestore for the map
          newLiveMap[entry.scbNo] = entry;

          // Update controller text based on the Firestore value.
          if (drumController.text != entry.drumNo) {
            drumController.text = entry.drumNo;
          }

          final String desiredStartText = entry.startingReading == null
              ? '' // Blank if null
              : entry.startingReading!.toStringAsFixed(
                  0,
                ); // Show 0 if it's 0, or other number
          if (startController.text != desiredStartText) {
            startController.text = desiredStartText;
          }

          final String desiredEndText = entry.endReading == null
              ? '' // Blank if null
              : entry.endReading!.toStringAsFixed(
                  0,
                ); // Show 0 if it's 0, or other number
          if (endController.text != desiredEndText) {
            endController.text = desiredEndText;
          }
        }

        // Dispose and remove controllers for entries no longer in the Firestore data
        _drumNoControllers.keys.toList().forEach((key) {
          if (!newLiveMap.containsKey(key)) {
            _drumNoControllers[key]?.dispose();
            _drumNoControllers.remove(key);
            _startingReadingControllers[key]?.dispose();
            _startingReadingControllers.remove(key);
            _endReadingControllers[key]?.dispose();
            _endReadingControllers.remove(key);
          }
        });

        _liveCableEntriesMap = newLiveMap;
      });
    });
  }

  @override
  void dispose() {
    _cableEntriesSubscription?.cancel();
    _drumNoControllers.forEach((key, controller) => controller.dispose());
    _startingReadingControllers.forEach(
      (key, controller) => controller.dispose(),
    );
    _endReadingControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// Updates the local CableEntry object in _liveCableEntriesMap
  /// and triggers a UI rebuild for live calculation display.
  /// This method is called by the onChanged callbacks of the TextFormFields.
  void _updateLocalCableEntry(
    String scbNo, {
    String? drumNo,
    double? startingReading,
    double? endReading,
    String? color, // NEW: Added color parameter
  }) {
    setState(() {
      final existingEntry = _liveCableEntriesMap[scbNo];
      if (existingEntry != null) {
        final updatedEntry = CableEntry(
          scbNo: existingEntry.scbNo,
          icrNo: existingEntry.icrNo,
          inverterNo: existingEntry.inverterNo,
          scheduledLength: existingEntry.scheduledLength,
          drumNo: drumNo ?? existingEntry.drumNo,
          startingReading: startingReading ?? existingEntry.startingReading,
          endReading: endReading ?? existingEntry.endReading,
          color: color ?? existingEntry.color, // NEW: Update color
        );
        _liveCableEntriesMap[scbNo] = updatedEntry;
      }
    });
  }

  /// Saves all modified cable entries from _liveCableEntriesMap to Firestore.
  Future<void> _saveAllChanges() async {
    if (_liveCableEntriesMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cable entries to save.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving changes...')));

    try {
      for (var entry in _liveCableEntriesMap.values) {
        // Only save if any relevant field has been modified
        if (entry.drumNo.isNotEmpty ||
            entry.startingReading != null ||
            entry.endReading != null ||
            entry.color != null) {
          // NEW: Use conditional logic to call the correct save function
          if (entry.color == 'Red') {
            await _firestoreService.saveCableEntry(entry);
          } else if (entry.color == 'Black') {
            await _firestoreService.saveCableEntryBlack(entry);
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All changes saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CableEntry> cableEntriesList =
        _liveCableEntriesMap.values.toList()
          ..sort((a, b) => a.scbNo.compareTo(b.scbNo));

    final double totalScheduled = cableEntriesList.fold(
      0.0,
      (sum, entry) => sum + entry.scheduledLength,
    );
    final double totalActual = cableEntriesList.fold(
      0.0,
      (sum, entry) => sum + entry.actualCutLength,
    );
    final double totalWastage = totalActual - totalScheduled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cable Reconciliation'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: cableEntriesList.length,
                itemBuilder: (context, index) {
                  final entry = cableEntriesList[index];
                  return CableReconciliationCard(
                    cableEntry: entry,
                    drumNoController: _drumNoControllers[entry.scbNo]!,
                    startingReadingController:
                        _startingReadingControllers[entry.scbNo]!,
                    endReadingController: _endReadingControllers[entry.scbNo]!,
                    onDrumNoChanged: (value) {
                      _updateLocalCableEntry(entry.scbNo, drumNo: value);
                    },
                    onStartingReadingChanged: (value) {
                      _updateLocalCableEntry(
                        entry.scbNo,
                        startingReading: value,
                      );
                    },
                    onEndReadingChanged: (value) {
                      _updateLocalCableEntry(entry.scbNo, endReading: value);
                    },
                    onColorSelected: (color) {
                      // NEW: Pass the color callback
                      _updateLocalCableEntry(entry.scbNo, color: color);
                    },
                    selectedColor:
                        entry.color, // NEW: Pass the current selected color
                  );
                },
              ),
            ),
            CableSummaryWidget(
              totalScheduled: 2 * totalScheduled,
              totalActual: 2 * totalActual,
              totalWastage: 2 * totalWastage,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: _saveAllChanges,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save All Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
