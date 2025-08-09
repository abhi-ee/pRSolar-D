// lib/constants/mms_material_quantities.dart (NEW FILE)
/// Defines the quantities of MMS materials per full and half table.
class MmsMaterialQuantities {
  // Quantities for a FULL table
  static const Map<String, int> fullTableQuantities = {
    'Purlin-1': 8,
    'Purlin-2': 12,
    'Purlin-3': 4,
    'Rafter': 10,
    'Front Bracing': 10,
    'Rear Bracing': 10,
    'Side Bracing': 2, // Assuming 'Side Breading' is 'Side Bracing'
    'Bracing connecting plate':
        10, // Assuming 'Bracing Connecting Plate' is 'Bracing connecting plate'
    'Strip': 2, // Assuming 'Strips' is 'Strip'
    'Modules': 58,
  };

  // Quantities for a HALF table
  static const Map<String, int> halfTableQuantities = {
    'Purlin-4': 8,
    'Purlin-5': 8,
    'Rafter': 5,
    'Front Bracing': 5,
    'Rear Bracing': 5,
    'Side Bracing': 1, // Assuming 'Side Breading' is 'Side Bracing'
    'Bracing connecting plate':
        5, // Assuming 'Bracing Connecting Plate' is 'Bracing connecting plate'
    'Strip': 2,
    'Modules': 29, // Assuming 'Strips' is 'Strip'
  };

  // List of all unique material names that we want to track progress for.
  // This list should match the 'name' property of MountingProgressItem.
  static const List<String> allMmsItems = [
    'Rafter',
    'Front Bracing',
    'Rear Bracing',
    'Side Bracing',
    'Bracing connecting plate',
    'Purlin-1',
    'Purlin-2',
    'Purlin-3',
    'Purlin-4', // New item for half table
    'Purlin-5', // New item for half table
    'Strip',
    'Modules', // modules  are added to constants
  ];
}
