// lib/screens/icr_info_screen.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for DocumentSnapshot

// Import your actual SolarProjectDashboardScreen, FirestoreService, and ScopeCalculationService
import 'package:solar_app/models/icr_info.dart';
import 'package:solar_app/screens/home_screen.dart';
import 'package:solar_app/services/firestore_service.dart'; // Import the actual FirestoreService
import 'package:solar_app/services/scope_calculation_service.dart'; // Import the actual ScopeCalculationService

// MODIFIED IcrInfo to include fromFirestore factory
// This class is a placeholder here, assuming the actual IcrInfo model
// (from models/icr_info.dart) has the fromFirestore factory.
// For the purpose of this modification, I'm adding the factory here to make it self-contained.

class IcrInfoScreen extends StatefulWidget {
  const IcrInfoScreen({super.key});

  @override
  State<IcrInfoScreen> createState() => _IcrInfoScreenState();
}

class _IcrInfoScreenState extends State<IcrInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ScopeCalculationService _scopeCalculationService =
      ScopeCalculationService();
  bool _isLoading = false;

  int? _selectedLocation;
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _1200GcFullTableController =
      TextEditingController();
  final TextEditingController _1200GcHalfTableController =
      TextEditingController();
  final TextEditingController _500GcFullTableController =
      TextEditingController();
  final TextEditingController _500GcHalfTableController =
      TextEditingController();
  final TextEditingController _dummyController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();

  @override
  void dispose() {
    _vendorController.dispose();
    _contactController.dispose();
    _1200GcFullTableController.dispose();
    _1200GcHalfTableController.dispose();
    _500GcFullTableController.dispose();
    _500GcHalfTableController.dispose();
    _dummyController.dispose();
    super.dispose();
  }

  Future<void> _submitIcrInfo() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a location.')),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });
      print(
        'ICRInfoScreen: Form validated. Attempting to save ICR info and calculate scope...',
      );

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception("User not authenticated. Cannot save data.");
        }

        final icrInfo = IcrInfo(
          location: _selectedLocation!,
          contact: _contactController.text.trim(),
          vendor: _vendorController.text.trim(),
          gc1200: {
            'FullTable': int.tryParse(_1200GcFullTableController.text) ?? 0,
            'HalfTable': int.tryParse(_1200GcHalfTableController.text) ?? 0,
          },
          gc500: {
            'FullTable': int.tryParse(_500GcFullTableController.text) ?? 0,
            'HalfTable': int.tryParse(_500GcHalfTableController.text) ?? 0,
          },
          dummy: int.tryParse(_dummyController.text) ?? 0,
          createdAt: DateTime.now(),
        );

        print('ICRInfoScreen: ICR Info object created.');

        // Save the selected location to the user's root document
        await _firestoreService.saveUserSelectedLocation(
          userId,
          _selectedLocation!,
        );
        print('ICRInfoScreen: User selected location saved.');

        // Save ICR info to the location-specific document
        await _firestoreService.saveIcrInfo(
          icrInfo,
        ); // This now uses icrInfo.location for doc ID
        print('ICRInfoScreen: ICR Info saved to Firestore.');

        final Map<String, double> calculatedMmsScope = _scopeCalculationService
            .calculateMmsScope(icrInfo);
        print('ICRInfoScreen: Calculated MMS Scope: $calculatedMmsScope');
        await _firestoreService.saveMmsScope(calculatedMmsScope);
        print('FirestoreService: Calculated MMS Scope saved to Firestore.');

        await _firestoreService.initializeMountingProgressItemsWithScope(
          calculatedMmsScope,
        );
        print(
          'ICRInfoScreen: Initialized mounting progress items with calculated scope.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ICR Information and Scope saved successfully!'),
            ),
          );
          print(
            'ICRInfoScreen: Registration complete. Navigating to SolarProjectDashboardScreen.',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete registration: ${e.toString()}'),
            ),
          );
          print('ICRInfoScreen: Error during registration process: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          print('ICRInfoScreen: _isLoading set to false.');
        }
      }
    } else {
      print('ICRInfoScreen: Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: CustomPaint(
        painter: _GreeneryBackgroundPainter(),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ICR Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildInputContainer(
                    child: DropdownButtonFormField<int>(
                      value: _selectedLocation,
                      decoration: _inputDecoration(
                        'Location',
                        Icons.location_on,
                      ),
                      hint: const Text('Select Location Number'),
                      items: List.generate(56, (index) => index + 1).map((
                        int number,
                      ) {
                        return DropdownMenuItem<int>(
                          value: number,
                          child: Text('Location $number'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedLocation = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a location';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Contact', Icons.phone),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.length != 10 || int.tryParse(value) == null) {
                          return 'Contact number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _vendorController,
                      decoration: _inputDecoration(
                        'Vendor Company Name',
                        Icons.business,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter vendor company name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildGroupContainer(
                    context,
                    title: '1200 GC',
                    children: [
                      _buildInputContainer(
                        child: TextFormField(
                          controller: _1200GcFullTableController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Full Table',
                            Icons.table_chart,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInputContainer(
                        child: TextFormField(
                          controller: _1200GcHalfTableController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Half Table',
                            Icons.table_chart_outlined,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildGroupContainer(
                    context,
                    title: '500 GC',
                    children: [
                      _buildInputContainer(
                        child: TextFormField(
                          controller: _500GcFullTableController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Full Table',
                            Icons.table_chart,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInputContainer(
                        child: TextFormField(
                          controller: _500GcHalfTableController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Half Table',
                            Icons.table_chart_outlined,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                int.tryParse(value) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildInputContainer(
                    child: TextFormField(
                      controller: _dummyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Dummy', Icons.help_outline),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitIcrInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Complete Registration'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.green.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      labelStyle: GoogleFonts.roboto(color: Colors.green[800]),
      hintStyle: GoogleFonts.roboto(color: Colors.grey[500]),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGroupContainer(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 25, thickness: 1, color: Colors.green),
          ...children,
        ],
      ),
    );
  }
}

class _GreeneryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0xFFE8F5E9);

    final Path path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.25,
    );
    path1.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width,
      size.height * 0.3,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();
    canvas.drawPath(
      path1,
      paint..color = const Color(0xFFF1F8E9).withOpacity(0.7),
    );

    final Path path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.95,
      size.width * 0.6,
      size.height * 0.8,
    );
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.65,
      size.width,
      size.height * 0.7,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(
      path2,
      paint..color = const Color(0xFFE8F5E9).withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
