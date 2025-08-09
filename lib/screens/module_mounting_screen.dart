// lib/screens/module_mounting_screen.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:solar_app/models/mounting_progress_item.dart';
import 'package:solar_app/widgets/progress_input_row.dart';
import 'package:solar_app/services/firestore_service.dart';

class ModuleMountingScreen extends StatefulWidget {
  const ModuleMountingScreen({super.key});

  @override
  State<ModuleMountingScreen> createState() => _ModuleMountingScreenState();
}

class _ModuleMountingScreenState extends State<ModuleMountingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  Map<String, TextEditingController> _todayProgressControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize default data in Firestore if the collection is empty.
    _firestoreService.initializeDefaultMountingProgressItems();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _todayProgressControllers.forEach(
      (key, controller) => controller.dispose(),
    );
    super.dispose();
  }

  /// Handles saving the daily progress to Firestore.
  void _saveDailyProgress(List<MountingProgressItem> currentItems) async {
    if (_formKey.currentState!.validate()) {
      // Create a list to hold items that actually had their 'Today's Progress' modified
      List<MountingProgressItem> itemsToSave = [];

      for (var item in currentItems) {
        final controller = _todayProgressControllers[item.name];
        if (controller != null && controller.text.isNotEmpty) {
          final double? progress = double.tryParse(controller.text);
          if (progress != null && progress > 0) {
            // Only process if a positive progress is entered
            // Create a copy of the item to modify, to avoid direct mutation of stream data
            final updatedItem = MountingProgressItem(
              name: item.name,
              todayProgress: progress,
              cumulativeProgress: item.cumulativeProgress,
              totalScope: item.totalScope,
              lastUpdated: item.lastUpdated,
            );
            updatedItem
                .addTodayProgress(); // Update cumulative and reset today's locally in the copy
            itemsToSave.add(updatedItem); // Add to list of items to save
            controller
                .clear(); // Clear the input field after adding to save list
          } else if (progress == 0 && controller.text.isNotEmpty) {
            // If user explicitly entered '0', clear the field as well
            controller.clear();
          }
        }
      }

      if (itemsToSave.isNotEmpty) {
        // Save all modified items in a batch or sequentially
        for (var item in itemsToSave) {
          await _firestoreService.saveMountingProgressItem(item);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily progress saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new progress entered.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Mounting Progress'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<MountingProgressItem>>(
          stream: _firestoreService.getMountingProgressItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No progress data found. Please complete ICR Info.',
                ),
              );
            }

            final List<MountingProgressItem> mountingItems = snapshot.data!;

            // Initialize controllers if they don't exist.
            // Crucially, do NOT update existing controller text based on snapshot data here,
            // as that would overwrite user input. The controllers should retain user's pending input.
            for (var item in mountingItems) {
              _todayProgressControllers.putIfAbsent(
                item.name,
                () => TextEditingController(
                  text: item.todayProgress.toStringAsFixed(0),
                ),
              );
            }

            // Optional: Clean up controllers for items no longer in the list (if dynamic list)
            // This scenario is less likely with a fixed list of MMS items but good practice.
            _todayProgressControllers.keys.toList().forEach((key) {
              if (!mountingItems.any((item) => item.name == key)) {
                _todayProgressControllers[key]?.dispose();
                _todayProgressControllers.remove(key);
              }
            });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header for the columns
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 600;
                          return Row(
                            children: [
                              Expanded(
                                flex: isSmallScreen ? 3 : 2,
                                child: Text(
                                  'Item Name',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                flex: isSmallScreen ? 2 : 1,
                                child: Text(
                                  'Today',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: isSmallScreen ? 2 : 1,
                                child: Text(
                                  'Cumulative',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: isSmallScreen ? 2 : 1,
                                child: Text(
                                  'Total Scope',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: mountingItems.length,
                        itemBuilder: (context, index) {
                          final item = mountingItems[index];
                          return ProgressInputRow(
                            item: item,
                            // Ensure the controller is passed correctly
                            todayProgressController:
                                _todayProgressControllers[item.name]!,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _saveDailyProgress(mountingItems),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Daily Progress'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
