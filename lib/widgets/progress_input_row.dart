import 'package:flutter/material.dart';
import 'package:solar_app/models/mounting_progress_item.dart';

class ProgressInputRow extends StatelessWidget {
  final MountingProgressItem item;
  final TextEditingController todayProgressController;

  const ProgressInputRow({
    super.key,
    required this.item,
    required this.todayProgressController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Item Name
              Expanded(
                flex: isSmallScreen ? 3 : 2,
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(
                width: 8,
              ), // Spacing between item name and input fields
              // Today's Progress Input
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: TextFormField(
                  controller: todayProgressController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0',
                    isDense: true, // Make the input field more compact
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Allow empty, as it means 0 progress for today
                    }
                    if (double.tryParse(value) == null) {
                      return ''; // Return empty string for subtle error indication
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Cumulative Progress (Read-only)
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: item.cumulativeProgress.toStringAsFixed(0),
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    fillColor: item.isCompleted
                        ? Colors.green[100]
                        : Colors.blueGrey[50], // Highlight if completed
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: item.isCompleted
                            ? Colors.green
                            : Colors.grey[400]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isCompleted
                        ? Colors.green[800]
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total Scope (Read-only)
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: item.totalScope.toStringAsFixed(0),
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    fillColor: Colors.blueGrey[50],
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
