import 'package:flutter/material.dart';
import 'package:solar_app/models/cable_entry.dart';
import 'package:google_fonts/google_fonts.dart';

class CableReconciliationCard extends StatelessWidget {
  final CableEntry cableEntry;
  final TextEditingController drumNoController;
  final TextEditingController startingReadingController;
  final TextEditingController endReadingController;
  final ValueChanged<String> onDrumNoChanged;
  final ValueChanged<double?> onStartingReadingChanged;
  final ValueChanged<double?> onEndReadingChanged;
  final ValueChanged<String?> onColorSelected; // Callback for color selection
  final String? selectedColor; // Current selected color

  const CableReconciliationCard({
    super.key,
    required this.cableEntry,
    required this.drumNoController,
    required this.startingReadingController,
    required this.endReadingController,
    required this.onDrumNoChanged,
    required this.onStartingReadingChanged,
    required this.onEndReadingChanged,
    required this.onColorSelected, // Required
    this.selectedColor, // Optional, but usually provided
  });

  InputDecoration _inputDecoration(String labelText, {IconData? icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey[700]) : null,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
      hintStyle: GoogleFonts.roboto(color: Colors.grey[500]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCB No: ${cableEntry.scbNo}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  'Inverter: ${cableEntry.inverterNo}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled Length: ${cableEntry.scheduledLength.toStringAsFixed(0)} m',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 24, thickness: 1, color: Colors.grey),

            TextFormField(
              controller: drumNoController,
              decoration: _inputDecoration(
                'Drum No',
                icon: Icons.precision_manufacturing,
              ),
              onChanged: onDrumNoChanged,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: startingReadingController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Starting Reading',
                icon: Icons.start,
              ),
              onChanged: (value) {
                final parsedValue = double.tryParse(value);
                onStartingReadingChanged(parsedValue);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: endReadingController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('End Reading', icon: Icons.stop),
              onChanged: (value) {
                final parsedValue = double.tryParse(value);
                onEndReadingChanged(parsedValue);
              },
            ),
            const SizedBox(height: 20),

            // NEW: Color Selector (Slide Button)
            Align(
              alignment: Alignment.center,
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'Red',
                    label: Text('Red'),
                    icon: Icon(Icons.circle, color: Colors.red),
                  ),
                  ButtonSegment<String>(
                    value: 'Black',
                    label: Text('Black'),
                    icon: Icon(Icons.circle, color: Colors.black),
                  ),
                ],
                selected: <String>{
                  selectedColor ?? '',
                }, // Handle null selectedColor
                onSelectionChanged: (Set<String> newSelection) {
                  if (newSelection.isNotEmpty) {
                    onColorSelected(newSelection.first);
                  } else {
                    onColorSelected(
                      null,
                    ); // Or a default if no selection is desired
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blueAccent.withOpacity(
                        0.2,
                      ); // Highlight selected
                    }
                    return Colors.grey[200]!; // Default background
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blueAccent; // Text color for selected
                    }
                    return Colors.black87; // Text color for unselected
                  }),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(color: Colors.grey[400]!, width: 1.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actual Cut Length (m):',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.blueGrey[700]),
                ),
                Text(
                  cableEntry.actualCutLength.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wastage:',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.blueGrey[700]),
                ),
                Text(
                  '${cableEntry.wastage.toStringAsFixed(2)} m',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cableEntry.getWastageColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
