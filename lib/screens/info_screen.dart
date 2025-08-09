// lib/screens/info_screen.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_app/models/icr_info.dart'; // Ensure this path is correct
import 'package:solar_app/services/auth_service.dart';
import 'package:solar_app/services/firestore_service.dart';
import 'package:solar_app/screens/auth_screen.dart';
import 'package:file_picker/file_picker.dart'; // Still needed for other file uploads (e.g., cable schedule)
import 'package:solar_app/models/cable_entry.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:permission_handler/permission_handler.dart';
// Removed: dart:io, path_provider, open_filex, http

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isUploadingCableSchedule = false;
  bool _isUploadingQualitySafetyFile = false;
  // Removed: bool _isLoadingDownload;

  // Removed: String? _localIcrDrawingPath;
  // Removed: String? _localIcrDrawingFileName;

  @override
  void initState() {
    super.initState();
    // Removed: Listener for ICR info changes related to drawing path
  }

  // Removed: Helper to extract filename from a URL (_getFileNameFromUrl)
  // Removed: Function to extract filename from URL and check for local file existence (_checkAndSetLocalDrawingPath)
  // Removed: Function to open the locally stored file (_viewLocalIcrDrawing)
  // Removed: Function to download the drawing from Firebase Storage (_downloadDrawing)

  Future<void> _uploadCableSchedule() async {
    setState(() {
      _isUploadingCableSchedule = true;
    });

    try {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'xlsx'],
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          final platformFile = result.files.single;
          final String fileName = platformFile.name;
          final Uint8List fileBytes = platformFile.bytes!;

          if (!fileName.toLowerCase().endsWith('.csv') &&
              !fileName.toLowerCase().endsWith('.xlsx')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a CSV or Excel (.xlsx) file.'),
                ),
              );
            }
            setState(() {
              _isUploadingCableSchedule = false;
            });
            return;
          }

          final String csvString = utf8.decode(fileBytes);
          final List<List<dynamic>> csvTable = const CsvToListConverter()
              .convert(csvString);

          if (csvTable.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selected file is empty or could not be parsed.',
                  ),
                ),
              );
            }
            setState(() {
              _isUploadingCableSchedule = false;
            });
            return;
          }

          final List<dynamic> header = csvTable[0];
          final int scbNoIndex = header.indexOf('SCB NO');
          final int icrNoIndex = header.indexOf('ICR NO');
          final int inverterNoIndex = header.indexOf('INVERTER NO');
          final int scheduledLengthIndex = header.indexOf(
            'TOTAL CABLE ROUTE LENGTH (2R X 1C X 300sqmm)( +&-)',
          );

          if (scbNoIndex == -1 ||
              icrNoIndex == -1 ||
              inverterNoIndex == -1 ||
              scheduledLengthIndex == -1) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'CSV headers missing. Expected: "SCB NO", "ICR NO", "INVERTER NO", "TOTAL CABLE ROUTE LENGTH (2R X 1C X 300sqmm)( +&-)".',
                  ),
                ),
              );
            }
            setState(() {
              _isUploadingCableSchedule = false;
            });
            return;
          }

          List<CableEntry> newCableEntries = [];
          for (int i = 1; i < csvTable.length; i++) {
            final row = csvTable[i];
            if (row.length > scheduledLengthIndex) {
              try {
                final String scbNo = row[scbNoIndex]?.toString() ?? '';
                final String icrNo = row[icrNoIndex]?.toString() ?? '';
                final String inverterNo =
                    row[inverterNoIndex]?.toString() ?? '';
                final double scheduledLength =
                    double.tryParse(
                      row[scheduledLengthIndex]?.toString() ?? '0.0',
                    ) ??
                    0.0;

                if (scbNo.isNotEmpty) {
                  newCableEntries.add(
                    CableEntry(
                      scbNo: scbNo,
                      icrNo: icrNo,
                      inverterNo: inverterNo,
                      scheduledLength: scheduledLength,
                    ),
                  );
                }
              } catch (e) {
                print('Error parsing row $i: $row - $e');
              }
            }
          }

          if (newCableEntries.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No valid cable entries found in the selected file.',
                  ),
                ),
              );
            }
            setState(() {
              _isUploadingCableSchedule = false;
            });
            return;
          }

          await _firestoreService.uploadCableScheduleFromCsv(
            newCableEntries,
            fileName,
            fileBytes,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${newCableEntries.length} cable entries uploaded and saved successfully!',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File picking cancelled or no file selected.'),
              ),
            );
          }
        }
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File picking canceled.')));
      }
    } catch (e) {
      print('Error uploading cable schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload cable schedule: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCableSchedule = false;
        });
      }
    }
  }

  // NEW: Method to upload Quality & Safety files
  Future<void> _uploadQualitySafetyFile() async {
    if (!_firestoreService.isDeveloper(currentUser?.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You do not have permission to upload Quality & Safety files.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploadingQualitySafetyFile = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ], // Allow common document and image types
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final platformFile = result.files.single;
        final String fileName = platformFile.name;
        final Uint8List fileBytes = platformFile.bytes!;
        final String fileExtension = fileName.split('.').last.toLowerCase();

        String fileType;
        if (fileExtension == 'pdf') {
          fileType = 'pdf';
        } else if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          fileType = 'image';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unsupported file type. Please select PDF, JPG, JPEG, or PNG.',
                ),
              ),
            );
          }
          setState(() {
            _isUploadingQualitySafetyFile = false;
          });
          return;
        }

        await _firestoreService.uploadQualitySafetyFile(platformFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quality & Safety file "$fileName" uploaded successfully!',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File picking cancelled or no file selected.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading Quality & Safety file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload Quality & Safety file: ${e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingQualitySafetyFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserDeveloper = _firestoreService.isDeveloper(
      currentUser?.uid,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Information'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vendor Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              StreamBuilder<IcrInfo?>(
                stream: _firestoreService.getIcrInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading ICR info: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return _buildInfoCard(
                      context,
                      title: 'ICR Information',
                      value:
                          'No ICR information found. Please complete registration.',
                      icon: Icons.info_outline,
                      valueColor: Colors.red,
                    );
                  }

                  final IcrInfo icrInfo = snapshot.data!;
                  return Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: 'Vendor Form Name',
                        value: 'Contractor ${icrInfo.vendor}',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        context,
                        title: 'Working Block (Location)',
                        value: 'Location ${icrInfo.location}',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        title: 'Mobile Number',
                        value: icrInfo.contact,
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        title: '1200 GC Table Count',
                        value:
                            'Full: ${icrInfo.gc1200['FullTable'] ?? 0}, Half: ${icrInfo.gc1200['HalfTable'] ?? 0}',
                        icon: Icons.table_chart_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        title: '500 GC Table Count',
                        value:
                            'Full: ${icrInfo.gc500['FullTable'] ?? 0}, Half: ${icrInfo.gc500['HalfTable'] ?? 0}',
                        icon: Icons.table_chart_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        title: 'Dummy Value',
                        value: '${icrInfo.dummy}',
                        icon: Icons.help_outline,
                      ),
                      const SizedBox(height: 16),
                      // Removed: ICR Drawing View/Download Card logic
                      _buildInfoCard(
                        context,
                        title: 'ICR Drawing',
                        value: 'Drawing functionality removed',
                        icon: Icons.picture_as_pdf,
                        valueColor: Colors.grey,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // Upload Cable Schedule Button
              _isUploadingCableSchedule
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _uploadCableSchedule,
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text('Upload Cable Schedule (CSV/Excel)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                    ),
              const SizedBox(height: 20),

              // NEW: Upload Quality & Safety File Button (Developer Only)
              if (isCurrentUserDeveloper) // Only show if current user is a developer
                _isUploadingQualitySafetyFile
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _uploadQualitySafetyFile,
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text('Upload Quality & Safety File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.indigo, // Different color for this upload
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                      ),
              if (isCurrentUserDeveloper)
                const SizedBox(height: 20), // Spacing if button is visible
              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully!')),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed: _buildDrawingActionCard widget
}
