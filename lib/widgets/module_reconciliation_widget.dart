// lib/widgets/module_reconciliation_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

class ModuleReconciliationWidget extends StatefulWidget {
  final int initialPreviouslyInstalledModules;
  final int initialDamagedModules;
  final int initialFullTables; // New: Pass full tables from ICR
  final int initialHalfTables; // New: Pass half tables from ICR
  final int initialScopeModules; // New: Pass calculated scope from ICR

  final Function(int totalInstalled, int todayInstalled, int damagedModules)
  onDataChanged;

  const ModuleReconciliationWidget({
    super.key,
    this.initialPreviouslyInstalledModules = 0,
    this.initialDamagedModules = 0,
    required this.onDataChanged,
    this.initialFullTables = 0, // Default to 0 if not provided
    this.initialHalfTables = 0, // Default to 0 if not provided
    this.initialScopeModules = 0, // Default to 0 if not provided
  });

  @override
  State<ModuleReconciliationWidget> createState() =>
      _ModuleReconciliationWidgetState();
}

class _ModuleReconciliationWidgetState
    extends State<ModuleReconciliationWidget> {
  // Removed _fullTablesController and _halfTablesController as they are no longer needed for input
  final TextEditingController _todayInstalledController =
      TextEditingController();
  final TextEditingController _damagedModulesController =
      TextEditingController();

  late int _scopeModules; // Now initialized from widget.initialScopeModules
  late int _previouslyInstalledModules;
  int _todayInstalledModules = 0;
  late int _totalInstalledModules;
  late int _damagedModules;

  @override
  void initState() {
    super.initState();
    _previouslyInstalledModules = widget.initialPreviouslyInstalledModules;
    _damagedModules = widget.initialDamagedModules;
    _scopeModules =
        widget.initialScopeModules; // Initialize scope from passed value

    _todayInstalledController.text = _todayInstalledModules.toString();
    _damagedModulesController.text = _damagedModules.toString();

    // Removed listeners for _fullTablesController and _halfTablesController
    _todayInstalledController.addListener(_updateTotalInstalled);
    _damagedModulesController.addListener(_updateDamagedModules);

    _updateTotalInstalled(); // Call once to set initial total installed
  }

  @override
  void dispose() {
    // Removed listeners for _fullTablesController and _halfTablesController
    _todayInstalledController.removeListener(_updateTotalInstalled);
    _damagedModulesController.removeListener(_updateDamagedModules);

    // Removed dispose for _fullTablesController and _halfTablesController
    _todayInstalledController.dispose();
    _damagedModulesController.dispose();
    super.dispose();
  }

  // _calculateScope is no longer needed here as scope is passed from parent
  // void _calculateScope() {
  //   setState(() {
  //     final int fullTables = int.tryParse(_fullTablesController.text) ?? 0;
  //     final int halfTables = int.tryParse(_halfTablesController.text) ?? 0;
  //     _scopeModules = (fullTables * 58) + (halfTables * 29);
  //   });
  // }

  void _updateTotalInstalled() {
    setState(() {
      _todayInstalledModules =
          int.tryParse(_todayInstalledController.text) ?? 0;
      _totalInstalledModules =
          _previouslyInstalledModules + _todayInstalledModules;
    });
    _notifyParent();
  }

  void _updateDamagedModules() {
    setState(() {
      _damagedModules = int.tryParse(_damagedModulesController.text) ?? 0;
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onDataChanged(
      _totalInstalledModules,
      _todayInstalledModules,
      _damagedModules,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Reconciliation Progress', // Updated title
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30, thickness: 1),

            // 1. Scope Section - Now displays calculated scope and source tables
            Text(
              'Project Scope (from ICR Info):',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Full Tables:',
              '${widget.initialFullTables}',
              Colors.blueGrey[700],
            ),
            _buildInfoRow(
              'Half Tables:',
              '${widget.initialHalfTables}',
              Colors.blueGrey[700],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Calculated Scope (Modules):',
              '$_scopeModules Modules',
              Colors.blueAccent,
            ),
            const Divider(height: 30, thickness: 1),

            // 2. Today Installed Section (User Input)
            TextField(
              controller: _todayInstalledController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Today Installed Modules',
                hintText: 'Enter number of modules installed today',
              ),
            ),
            const SizedBox(height: 16),

            // 3. Total Installed Section (Cumulative Display)
            _buildInfoRow(
              'Previously Installed Modules:',
              '$_previouslyInstalledModules Modules',
              Colors.grey[700],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total Installed Modules (Cumulative):',
              '$_totalInstalledModules Modules',
              Colors.green,
            ),
            const Divider(height: 30, thickness: 1),

            // 4. Damaged Modules Section (User Input)
            TextField(
              controller: _damagedModulesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Damaged Modules',
                hintText: 'Enter number of damaged modules',
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Total Damaged Modules:',
              '$_damagedModules Modules',
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
