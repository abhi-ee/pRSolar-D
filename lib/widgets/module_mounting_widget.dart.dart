// lib/widgets/module_mounting_widget.dart (NEW FILE - Dedicated for Module Mounting)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

class ModuleMountingWidget extends StatefulWidget {
  final int initialPreviouslyInstalledModules;
  final int initialDamagedModules;
  final Function(int totalInstalled, int todayInstalled, int damagedModules)
  onDataChanged;

  const ModuleMountingWidget({
    super.key,
    this.initialPreviouslyInstalledModules = 0,
    this.initialDamagedModules = 0,
    required this.onDataChanged,
  });

  @override
  State<ModuleMountingWidget> createState() => _ModuleMountingWidgetState();
}

class _ModuleMountingWidgetState extends State<ModuleMountingWidget> {
  final TextEditingController _fullTablesController = TextEditingController();
  final TextEditingController _halfTablesController = TextEditingController();
  final TextEditingController _todayInstalledController =
      TextEditingController();
  final TextEditingController _damagedModulesController =
      TextEditingController();

  int _scopeModules = 0;
  int _previouslyInstalledModules = 0;
  int _todayInstalledModules = 0;
  int _totalInstalledModules = 0;
  int _damagedModules = 0;

  @override
  void initState() {
    super.initState();
    _previouslyInstalledModules = widget.initialPreviouslyInstalledModules;
    _damagedModules = widget.initialDamagedModules;

    _todayInstalledController.text = _todayInstalledModules.toString();
    _damagedModulesController.text = _damagedModules.toString();

    _fullTablesController.addListener(_calculateScope);
    _halfTablesController.addListener(_calculateScope);
    _todayInstalledController.addListener(_updateTotalInstalled);
    _damagedModulesController.addListener(_updateDamagedModules);

    _updateTotalInstalled();
  }

  @override
  void dispose() {
    _fullTablesController.removeListener(_calculateScope);
    _halfTablesController.removeListener(_calculateScope);
    _todayInstalledController.removeListener(_updateTotalInstalled);
    _damagedModulesController.removeListener(_updateDamagedModules);

    _fullTablesController.dispose();
    _halfTablesController.dispose();
    _todayInstalledController.dispose();
    _damagedModulesController.dispose();
    super.dispose();
  }

  void _calculateScope() {
    setState(() {
      final int fullTables = int.tryParse(_fullTablesController.text) ?? 0;
      final int halfTables = int.tryParse(_halfTablesController.text) ?? 0;
      _scopeModules = (fullTables * 58) + (halfTables * 29);
    });
  }

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
              'Module Mounting Progress', // Specific title for mounting
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30, thickness: 1),

            // 1. Scope Section
            Text(
              'Calculate Scope:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fullTablesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Full Tables (58 modules/table)',
                      hintText: 'e.g., 10',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _halfTablesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Half Tables (29 modules/table)',
                      hintText: 'e.g., 5',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Calculated Scope:',
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
