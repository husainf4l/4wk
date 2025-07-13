import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../models/session.dart';
import '../../../services/test_drive_service.dart';
import '../../../services/image_handling_service.dart';
import '../../../widgets/image_grid_widget.dart';
import '../../../widgets/notes_editor_widget.dart';
import '../../../widgets/detail_screen_header.dart';
import '../../../widgets/observations_list_widget.dart';
import '../session_details_screen.dart';

class TestDriveDetailsScreen extends StatefulWidget {
  // Required parameters
  final String sessionId;
  final String clientId;
  final String carId;
  final String clientName;
  final String carDetails;

  // Optional parameters
  final Session? session;
  final String? testDriveId;

  const TestDriveDetailsScreen({
    super.key,
    this.session,
    required this.clientName,
    required this.carDetails,
    this.testDriveId,
    String? sessionId,
    String? clientId,
    String? carId,
  }) : sessionId = sessionId ?? '',
       clientId = clientId ?? '',
       carId = carId ?? '';

  @override
  State<TestDriveDetailsScreen> createState() => _TestDriveDetailsScreenState();
}

class _TestDriveDetailsScreenState extends State<TestDriveDetailsScreen> {
  final TestDriveService _testDriveService = TestDriveService();
  final ImageHandlingService _imageHandlingService = ImageHandlingService();
  final TextEditingController _customObservationController =
      TextEditingController();

  String? _notes;
  List<Map<String, dynamic>> _observations = [];
  final List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;

  // Initialize actual sessionId, clientId, and carId based on widget properties
  late String _sessionId;
  late String _clientId;
  late String _carId;

  @override
  void initState() {
    super.initState();
    // Initialize IDs based on session or direct values
    _sessionId = widget.session?.id ?? widget.sessionId;
    _clientId = widget.session?.client['id'] ?? widget.clientId;
    _carId = widget.session?.car['id'] ?? widget.carId;

    // If no testDriveId is provided, start in edit mode for a new test drive
    if (widget.testDriveId == null) {
      _isEditing = true;
    }
    _fetchTestDrive();
  }

  @override
  void dispose() {
    _customObservationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTestDrive() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.testDriveId != null) {
        // Fetch existing test drive from jobCard collection
        final testDriveDoc =
            await FirebaseFirestore.instance
                .collection('jobCard')
                .doc(widget.testDriveId)
                .get();

        if (testDriveDoc.exists) {
          final data = testDriveDoc.data() as Map<String, dynamic>;
          setState(() {
            _notes = data['notes'] as String?;
            if (data['observations'] != null) {
              _observations = List<Map<String, dynamic>>.from(
                data['observations'],
              );
            }

            // Load existing image URLs
            if (data['images'] != null) {
              _uploadedImageUrls = List<String>.from(data['images']);
            }
          });
        }
      }
      // If testDriveId is null, we're creating a new test drive, so no need to fetch
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading test drive: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _showEditNotesDialog() {
    NotesEditorWidget.showEditDialog(
      context,
      initialValue: _notes ?? '',
      onSave: (value) {
        if (mounted) {
          setState(() {
            _notes = value;
          });
        }
      },
    );
  }

  void _addCustomObservation() {
    final observation = _customObservationController.text.trim();
    if (observation.isNotEmpty) {
      setState(() {
        _observations.add({
          'observation': observation,
          'argancy': 'low', // Default value
          'price': 0, // Default price in AED
        });
        _customObservationController.clear();
      });
      FocusScope.of(context).unfocus();
    } else {
      _showAddObservationDialog();
    }
  }

  void _showAddObservationDialog() {
    ObservationsListWidget.showAddObservationDialog(
      context,
      onAddObservation: (observation, argancy) {
        if (mounted) {
          setState(() {
            _observations.add({
              'observation': observation,
              'argancy': argancy,
              'price': 0, // Default price in AED
            });
          });
        }
      },
    );
  }

  void _editArgancy(Map<String, dynamic> observation, String newArgancy) {
    setState(() {
      final index = _observations.indexOf(observation);
      if (index != -1) {
        _observations[index]['argancy'] = newArgancy;
      }
    });
  }

  void _removeObservation(Map<String, dynamic> observation) {
    setState(() {
      _observations.remove(observation);
    });
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    // Validate required IDs
    if (_sessionId.isEmpty || _clientId.isEmpty || _carId.isEmpty) {
      Get.snackbar(
        'Error',
        'Missing required session, client, or car information',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // First upload any selected images to Firebase Storage
      if (_selectedImages.isNotEmpty) {
        final List<String> newImageUrls = await _imageHandlingService
            .uploadImagesToFirebase(
              imageFiles: _selectedImages,
              storagePath: 'test_drive_images',
              uniqueIdentifier: 'session_$_sessionId',
            );

        _uploadedImageUrls.addAll(newImageUrls);
        _selectedImages.clear();
      }

      String? testDriveId = widget.testDriveId;

      if (testDriveId != null) {
        // Update existing test drive
        await _testDriveService.updateTestDrive(
          testDriveId: testDriveId,
          notes: _notes ?? '',
          observations: _observations,
          images: _uploadedImageUrls,
        );
      } else {
        // Create new test drive
        testDriveId = await _testDriveService.saveTestDrive(
          sessionId: _sessionId,
          carId: _carId,
          clientId: _clientId,
          notes: _notes ?? '',
          observations: _observations,
          images: _uploadedImageUrls,
        );

        // Update session with the new test drive ID directly
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(_sessionId)
            .update({
              'testDriveId': testDriveId,
              'status': 'TESTED', // Update session status as tested
            });
      }

      Get.snackbar(
        'Success',
        'Test drive saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate directly back to the session details screen with updated session data
      final sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc(_sessionId)
              .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data() as Map<String, dynamic>;
        // Create Session object with both the map and ID
        final session = Session.fromMap(sessionData, _sessionId);
        // Navigate to session details with updated session
        Get.off(() => SessionDetailsScreen(session: session));
      } else {
        // If session doesn't exist for some reason, just go back
        Get.back(result: {'refresh': true});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving test drive: $e';
      });

      Get.snackbar(
        'Error',
        'Failed to save test drive: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showImageSourceOptions() {
    _imageHandlingService.showImageSourceOptions(
      context,
      onImageSelected: (File? file) {
        if (file != null && mounted) {
          setState(() {
            _selectedImages.add(file);
          });
        }
      },
      onMultipleImagesSelected: (List<File> files) {
        if (mounted) {
          setState(() {
            _selectedImages.addAll(files);
          });
        }
      },
      allowMultiple: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Test Drive',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with the reusable DetailScreenHeader widget
            DetailScreenHeader(
              title:
                  widget.testDriveId == null ? 'New Test Drive' : 'Test Drive',
              subtitle: widget.clientName,
              isEditing: _isEditing,
              isSaving: _isSaving,
              onSavePressed: _saveChanges,
              onEditPressed: _toggleEditMode,
              onCancelPressed:
                  widget.testDriveId == null ? null : _toggleEditMode,
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car details
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withAlpha(51),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.carDetails,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Images Section using the reusable ImageGridWidget
                      Text(
                        'Test Drive Images',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ImageGridWidget(
                        uploadedImageUrls: _uploadedImageUrls,
                        selectedImages: _selectedImages,
                        isEditing: _isEditing,
                        onRemoveUploadedImage:
                            _isEditing
                                ? (index) {
                                  setState(() {
                                    _uploadedImageUrls.removeAt(index);
                                  });
                                }
                                : null,
                        onRemoveSelectedImage:
                            _isEditing
                                ? (index) {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                }
                                : null,
                      ),

                      const SizedBox(height: 24),

                      // Notes Section using the reusable NotesEditorWidget
                      Text(
                        'Test Drive Notes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NotesEditorWidget(
                        notes: _notes,
                        isEditing: _isEditing,
                        onEditPressed: _showEditNotesDialog,
                      ),

                      const SizedBox(height: 24),

                      // Observations Section using the reusable ObservationsListWidget
                      Text(
                        'Test Drive Observations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ObservationsListWidget(
                        observations: _observations,
                        isEditing: _isEditing,
                        onRemoveObservation:
                            _isEditing ? _removeObservation : null,
                        onAddObservation:
                            _isEditing ? _showAddObservationDialog : null,
                        onEditArgancy: _isEditing ? _editArgancy : null,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Input area for adding observations - only shown in edit mode
            if (_isEditing)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.attach_file,
                                  color: theme.primaryColor,
                                ),
                                onPressed: _showImageSourceOptions,
                                tooltip: 'Add Images',
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _customObservationController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a test drive observation...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _addCustomObservation(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _addCustomObservation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
