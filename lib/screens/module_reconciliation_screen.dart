import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_app/models/module_reconciliation.dart';
import 'package:solar_app/services/firestore_service.dart';

class ModuleReconciliationScreen extends StatefulWidget {
  const ModuleReconciliationScreen({super.key});

  @override
  State<ModuleReconciliationScreen> createState() =>
      _ModuleReconciliationScreenState();
}

class _ModuleReconciliationScreenState
    extends State<ModuleReconciliationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // State for UI
  bool _isLoading = true;
  String _tableType = 'Full'; // 'Full' or 'Half'

  // Controllers for user input
  final TextEditingController _todayInstalledController =
      TextEditingController();
  final TextEditingController _damagedController = TextEditingController();

  // Data variables
  int _scope = 58;
  int _previouslyInstalled = 0;
  int _todayInstalled = 0;
  int _totalInstalled = 0;
  int _damagedModules = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Add listeners to update the UI live as the user types
    _todayInstalledController.addListener(_updateCalculations);
    _damagedController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _todayInstalledController.dispose();
    _damagedController.dispose();
    super.dispose();
  }

  /// Load initial data from Firestore
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _firestoreService.getModuleReconciliation();
    setState(() {
      _previouslyInstalled = data.totalInstalled;
      // Note: We don't load today's damaged count, it's always a new entry
      _updateCalculations();
      _isLoading = false;
    });
  }

  /// Updates all calculated values based on current input
  void _updateCalculations() {
    setState(() {
      _scope = _tableType == 'Full' ? 58 : 29;
      _todayInstalled = int.tryParse(_todayInstalledController.text) ?? 0;
      _damagedModules = int.tryParse(_damagedController.text) ?? 0;
      _totalInstalled = _previouslyInstalled + _todayInstalled;
    });
  }

  /// Save the updated data to Firebase
  Future<void> _saveData() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('💾 Saving data...')));

    final newReconciliationData = ModuleReconciliation(
      totalInstalled: _totalInstalled, // Save the new cumulative total
      totalDamaged:
          _damagedModules, // For simplicity, we can just store today's damage
      lastUpdated: DateTime.now(),
    );

    await _firestoreService.updateModuleReconciliation(newReconciliationData);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Data Saved Successfully!')));

    // Reload the screen with the new "previously installed" value
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Reconciliation'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableTypeSelector(),
                  const SizedBox(height: 24),
                  _buildInfoBar(
                    'Scope',
                    '$_scope Modules',
                    Icons.api,
                    Colors.blue,
                  ),
                  _buildInfoBar(
                    'Total Installed',
                    '$_totalInstalled Modules',
                    Icons.foundation,
                    Colors.green,
                  ),
                  _buildInfoBar(
                    'Damage Modules',
                    '$_damagedModules Modules',
                    Icons.warning,
                    Colors.orange,
                  ),
                  const Divider(height: 40, thickness: 1),
                  _buildTextField(
                    controller: _todayInstalledController,
                    label: 'Today Installed',
                    icon: Icons.add_circle,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _damagedController,
                    label: 'Damaged Modules Today',
                    icon: Icons.heart_broken_outlined,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveData,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Data'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget for the dropdown selector
  Widget _buildTableTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tableType,
          isExpanded: true,
          icon: const Icon(Icons.table_chart),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _tableType = newValue;
                _updateCalculations();
              });
            }
          },
          items: <String>['Full', 'Half'].map<DropdownMenuItem<String>>((
            String value,
          ) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text('$value Table'),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper widget for text input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Helper widget for the info display bars
  Widget _buildInfoBar(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
