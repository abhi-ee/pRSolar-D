import 'package:flutter/material.dart';

class CableSummaryWidget extends StatelessWidget {
  final double totalScheduled;
  final double totalActual;
  final double totalWastage;

  const CableSummaryWidget({
    super.key,
    required this.totalScheduled,
    required this.totalActual,
    required this.totalWastage,
  });

  /// Determines the color for displaying total wastage based on its value.
  Color _getWastageColor() {
    if (totalWastage > 0) {
      return Colors.green; // Positive wastage
    } else if (totalWastage < 0) {
      return Colors.red; // Negative wastage
    } else {
      return Colors.grey; // Zero wastage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color:
          Colors.blueGrey[100], // A slightly different background for summary
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Overall Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blueGrey[800]),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 20, thickness: 1),
            _buildSummaryRow(
              context,
              'Total Scheduled:',
              '${totalScheduled.toStringAsFixed(0)} m',
              Colors.blueGrey,
            ),
            _buildSummaryRow(
              context,
              'Total Actual:',
              '${totalActual.toStringAsFixed(0)} m',
              Colors.blueGrey,
            ),
            _buildSummaryRow(
              context,
              'Total Wastage:',
              '${totalWastage.toStringAsFixed(2)} m',
              _getWastageColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
