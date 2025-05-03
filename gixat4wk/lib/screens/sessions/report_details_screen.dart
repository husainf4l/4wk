import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/session.dart';
import '../../services/report_service.dart';
import '../../services/image_handling_service.dart';
import '../../widgets/detail_screen_header.dart';
import '../../widgets/notes_editor_widget.dart';
import '../../widgets/image_grid_widget.dart';
import '../sessions/session_details_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  // Required parameter - only need sessionId
  final String sessionId;

  // Optional parameter - reportId
  final String? reportId;

  const ReportDetailsScreen({
    super.key,
    required this.sessionId,
    this.reportId,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final ReportService _reportService = ReportService();
  final ImageHandlingService _imageHandlingService = ImageHandlingService();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _recommendationsController =
      TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientCityController = TextEditingController();
  final TextEditingController _clientCountryController =
      TextEditingController();
  final TextEditingController _newItemController = TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;
  
  // Active editing section tracking
  String _activeEditSection = '';
  final List<File> _selectedImages = [];

  // Session data
  Session? _session;

  // Client and car info
  String _clientName = 'Loading...';
  String _carDetails = 'Loading...'; // Used to display car details in the UI
  String _clientId = '';
  String _carId = '';

  // Report data variables
  String? _clientNotes;
  List<Map<String, dynamic>> _clientRequests = [];
  List<String> _clientNotesImages = [];

  String? _inspectionNotes;
  List<Map<String, dynamic>> _inspectionFindings = [];
  List<String> _inspectionImages = [];

  String? _testDriveNotes;
  List<Map<String, dynamic>> _testDriveObservations = [];
  List<String> _testDriveImages = [];

  // Client and car info
  Map<String, dynamic> _clientData = {};
  Map<String, dynamic> _carData = {};

  // Rating (1-5)
  int _conditionRating = 3;

  @override
  void initState() {
    super.initState();

    // If no reportId is provided, start in edit mode for a new report
    if (widget.reportId == null) {
      _isEditing = true;
    }

    _loadSessionAndData();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _recommendationsController.dispose();
    _clientPhoneController.dispose();
    _clientCityController.dispose();
    _clientCountryController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionAndData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, fetch the complete session data using the sessionId
      final sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc(widget.sessionId)
              .get();

      if (!sessionDoc.exists) {
        setState(() {
          _errorMessage = 'Session not found. Please try again.';
        });
        return;
      }

      // Create session object from the document
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      _session = Session.fromMap(sessionData, widget.sessionId);

      // Now get client and car data from their respective collections
      await _fetchClientAndCarData();

      // Then load the report data
      await _loadReportData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading session data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchClientAndCarData() async {
    if (_session == null) return;

    try {
      // Get the client data from customers collection
      final clientId = _session!.client['id'];
      _clientId = clientId;

      final clientDoc =
          await FirebaseFirestore.instance
              .collection('clients')
              .doc(clientId)
              .get();

      if (clientDoc.exists) {
        _clientData = clientDoc.data() as Map<String, dynamic>;
      } else {
        // Fallback to session data
        _clientData = _session!.client;
      }

      // Get client name
      _clientName = _clientData['name'] ?? 'Unknown Client';

      // Get the car data from cars collection
      final carId = _session!.car['id'];
      _carId = carId;

      final carDoc =
          await FirebaseFirestore.instance.collection('cars').doc(carId).get();

      if (carDoc.exists) {
        _carData = carDoc.data() as Map<String, dynamic>;
      } else {
        // Fallback to session data
        _carData = _session!.car;
      }

      // Format car details string
      final carMake = _carData['make'] ?? '';
      final carModel = _carData['model'] ?? '';
      final plateNumber = _carData['plateNumber'] ?? '';
      _carDetails =
          '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

      // Set form field values
      _clientPhoneController.text = _clientData['phone'] ?? '';

      // Handle nested address fields
      if (_clientData.containsKey('address') && _clientData['address'] is Map) {
        Map<String, dynamic> address =
            _clientData['address'] as Map<String, dynamic>;
        _clientCityController.text = address['city'] ?? '';
        _clientCountryController.text = address['country'] ?? '';
      } else {
        // Fallback to direct properties if address map doesn't exist
        _clientCityController.text = _clientData['city'] ?? '';
        _clientCountryController.text = _clientData['country'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching client/car data: $e');
      // Fallback to session data if there's an error
      _clientData = _session!.client;
      _carData = _session!.car;
      _clientName = _clientData['name'] ?? 'Unknown Client';

      final carMake = _carData['make'] ?? '';
      final carModel = _carData['model'] ?? '';
      final plateNumber = _carData['plateNumber'] ?? '';
      _carDetails =
          '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';
    }
  }

  Future<void> _loadReportData() async {
    if (_session == null) return;

    try {
      // Load existing report if reportId exists
      if (widget.reportId != null) {
        final reportData = await _reportService.getReport(widget.reportId!);
        if (reportData != null) {
          setState(() {
            // Set controllers
            _summaryController.text = reportData['summary'] ?? '';
            _recommendationsController.text =
                reportData['recommendations'] ?? '';

            // Set other report fields
            _conditionRating = reportData['conditionRating'] ?? 3;
            _clientNotes = reportData['clientNotes'];
            _inspectionNotes = reportData['inspectionNotes'];
            _testDriveNotes = reportData['testDriveNotes'];

            // Set lists
            if (reportData['clientRequests'] != null) {
              _clientRequests = List<Map<String, dynamic>>.from(
                reportData['clientRequests'],
              );
            }
            if (reportData['inspectionFindings'] != null) {
              _inspectionFindings = List<Map<String, dynamic>>.from(
                reportData['inspectionFindings'],
              );
            }
            if (reportData['testDriveObservations'] != null) {
              _testDriveObservations = List<Map<String, dynamic>>.from(
                reportData['testDriveObservations'],
              );
            }

            // Set images
            if (reportData['clientNotesImages'] != null) {
              _clientNotesImages = List<String>.from(
                reportData['clientNotesImages'],
              );
            }
            if (reportData['inspectionImages'] != null) {
              _inspectionImages = List<String>.from(
                reportData['inspectionImages'],
              );
            }
            if (reportData['testDriveImages'] != null) {
              _testDriveImages = List<String>.from(reportData['testDriveImages']);
            }
          });
          return;
        }
      }

      // If no existing report or failed to load, gather data from source records
      // Load client notes data if it exists
      if (_session!.clientNoteId != null) {
        final clientNotesData = await _reportService.getClientNotes(
          _session!.clientNoteId!,
        );
        if (clientNotesData != null) {
          setState(() {
            _clientNotes = clientNotesData['notes'];
            if (clientNotesData['requests'] != null) {
              _clientRequests = List<Map<String, dynamic>>.from(
                clientNotesData['requests'],
              );
            }
            if (clientNotesData['images'] != null) {
              _clientNotesImages = List<String>.from(clientNotesData['images']);
            }
          });
        }
      }

      // Load inspection data if it exists
      if (_session!.inspectionId != null) {
        final inspectionData = await _reportService.getInspection(
          _session!.inspectionId!,
        );
        if (inspectionData != null) {
          setState(() {
            _inspectionNotes = inspectionData['notes'];
            if (inspectionData['findings'] != null) {
              _inspectionFindings = List<Map<String, dynamic>>.from(
                inspectionData['findings'],
              );
            }
            if (inspectionData['images'] != null) {
              _inspectionImages = List<String>.from(inspectionData['images']);
            }
          });
        }
      }

      // Load test drive data if it exists
      if (_session!.testDriveId != null) {
        final testDriveData = await _reportService.getTestDrive(
          _session!.testDriveId!,
        );
        if (testDriveData != null) {
          setState(() {
            _testDriveNotes = testDriveData['notes'];
            if (testDriveData['observations'] != null) {
              _testDriveObservations = List<Map<String, dynamic>>.from(
                testDriveData['observations'],
              );
            }
            if (testDriveData['images'] != null) {
              _testDriveImages = List<String>.from(testDriveData['images']);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading report data: $e';
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _showEditClientNotesDialog() {
    NotesEditorWidget.showEditDialog(
      context,
      initialValue: _clientNotes ?? '',
      onSave: (value) {
        if (mounted) {
          setState(() {
            _clientNotes = value;
          });
        }
      },
    );
  }

  void _showEditInspectionNotesDialog() {
    NotesEditorWidget.showEditDialog(
      context,
      initialValue: _inspectionNotes ?? '',
      onSave: (value) {
        if (mounted) {
          setState(() {
            _inspectionNotes = value;
          });
        }
      },
    );
  }

  void _showEditTestDriveNotesDialog() {
    NotesEditorWidget.showEditDialog(
      context,
      initialValue: _testDriveNotes ?? '',
      onSave: (value) {
        if (mounted) {
          setState(() {
            _testDriveNotes = value;
          });
        }
      },
    );
  }
  
  // Method to edit an individual client request
  void _editItemDialog(Map<String, dynamic> item, String type) {
    final TextEditingController textController = TextEditingController(
      text: type == 'request' 
          ? item['request'] 
          : type == 'finding' 
              ? item['finding'] 
              : item['observation'],
    );
    final priceController = TextEditingController(
      text: (item['price'] ?? 0).toString(),
    );
    String selectedArgancy = item['argancy'] ?? 'low';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${type.capitalize}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: type.capitalize,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              Text('Urgency Level:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUrgencyButton(context, 'Low', Colors.green, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                  _buildUrgencyButton(context, 'Medium', Colors.orange, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                  _buildUrgencyButton(context, 'High', Colors.red, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                ],
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (AED)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) return;
                
                if (type == 'request') {
                  item['request'] = textController.text.trim();
                } else if (type == 'finding') {
                  item['finding'] = textController.text.trim();
                } else {
                  item['observation'] = textController.text.trim();
                }
                
                item['argancy'] = selectedArgancy;
                item['price'] = int.tryParse(priceController.text) ?? 0;
                
                setState(() {});
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add a new item dialog for requests, findings, or observations
  void _addNewItemDialog(String type) {
    final TextEditingController textController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    String selectedArgancy = 'low';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New ${type.capitalize}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: type.capitalize,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              Text('Urgency Level:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUrgencyButton(context, 'Low', Colors.green, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                  _buildUrgencyButton(context, 'Medium', Colors.orange, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                  _buildUrgencyButton(context, 'High', Colors.red, selectedArgancy, 
                    (value) => setState(() => selectedArgancy = value)),
                ],
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (AED)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) return;
                
                Map<String, dynamic> newItem = {
                  'argancy': selectedArgancy,
                  'price': int.tryParse(priceController.text) ?? 0,
                };
                
                if (type == 'request') {
                  newItem['request'] = textController.text.trim();
                  _clientRequests.add(newItem);
                } else if (type == 'finding') {
                  newItem['finding'] = textController.text.trim();
                  _inspectionFindings.add(newItem);
                } else {
                  newItem['observation'] = textController.text.trim();
                  _testDriveObservations.add(newItem);
                }
                
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method to remove an item
  void _removeItem(dynamic item, String type) {
    setState(() {
      if (type == 'request') {
        _clientRequests.remove(item);
      } else if (type == 'finding') {
        _inspectionFindings.remove(item);
      } else if (type == 'observation') {
        _testDriveObservations.remove(item);
      }
    });
  }
  
  // Method to change urgency directly
  void _changeUrgency(dynamic item, String newUrgency) {
    setState(() {
      item['argancy'] = newUrgency;
    });
  }
  
  // Method to show image picker for different sections
  void _showImagePicker(String section) {
    setState(() {
      _activeEditSection = section;
    });
    
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
  
  // Process selected images after picking
  Future<void> _processSelectedImages() async {
    if (_selectedImages.isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Upload images to Firebase Storage
      final List<String> newImageUrls = await _imageHandlingService.uploadImagesToFirebase(
        imageFiles: _selectedImages,
        storagePath: 'report_images',
        uniqueIdentifier: 'report_${widget.sessionId}',
      );
      
      // Add new image URLs to the appropriate section
      setState(() {
        if (_activeEditSection == 'client') {
          _clientNotesImages.addAll(newImageUrls);
        } else if (_activeEditSection == 'inspection') {
          _inspectionImages.addAll(newImageUrls);
        } else if (_activeEditSection == 'testdrive') {
          _testDriveImages.addAll(newImageUrls);
        }
        
        _selectedImages.clear();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload images: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  // Remove image from a specific section
  void _removeImage(int index, String section) {
    setState(() {
      if (section == 'client') {
        _clientNotesImages.removeAt(index);
      } else if (section == 'inspection') {
        _inspectionImages.removeAt(index);
      } else if (section == 'testdrive') {
        _testDriveImages.removeAt(index);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    // Process any pending image uploads
    await _processSelectedImages();
    
    // Validate required IDs
    if (_clientId.isEmpty || _carId.isEmpty) {
      Get.snackbar(
        'Error',
        'Missing required client or car information',
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
      // Update client data with form fields
      _clientData['phone'] = _clientPhoneController.text;

      // Handle address structure properly
      if (!_clientData.containsKey('address')) {
        _clientData['address'] = {};
      }

      if (_clientData['address'] is! Map) {
        _clientData['address'] = {};
      }

      // Update the address map
      (_clientData['address'] as Map<String, dynamic>)['city'] =
          _clientCityController.text;
      (_clientData['address'] as Map<String, dynamic>)['country'] =
          _clientCountryController.text;

      // Create report data
      final Map<String, dynamic> reportData = {
        'summary': _summaryController.text,
        'recommendations': _recommendationsController.text,
        'conditionRating': _conditionRating,
        'clientNotes': _clientNotes,
        'inspectionNotes': _inspectionNotes,
        'testDriveNotes': _testDriveNotes,
        'clientRequests': _clientRequests,
        'inspectionFindings': _inspectionFindings,
        'testDriveObservations': _testDriveObservations,
        'clientNotesImages': _clientNotesImages,
        'inspectionImages': _inspectionImages,
        'testDriveImages': _testDriveImages,
      };

      String reportId = widget.reportId ?? '';

      if (reportId.isEmpty) {
        // Create new report
        reportId = await _reportService.saveReport(
          sessionId: widget.sessionId,
          carId: _carId,
          clientId: _clientId,
          clientData: _clientData,
          carData: _carData,
          reportData: reportData,
        );

        // Update session with the new report ID
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .update({
              'reportId': reportId,
              'status': 'REPORTED', // Update session status as reported
              'updatedAt': DateTime.now(),
            });
      } else {
        // Update existing report
        await _reportService.updateReport(
          reportId: reportId,
          sessionId: widget.sessionId,
          clientData: _clientData,
          carData: _carData,
          reportData: reportData,
        );
      }

      Get.snackbar(
        'Success',
        'Report saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate directly back to the session details screen with updated session data
      final sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc(widget.sessionId)
              .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data() as Map<String, dynamic>;
        // Create Session object with both the map and ID
        final session = Session.fromMap(sessionData, widget.sessionId);
        // Navigate to session details with updated session
        Get.off(() => SessionDetailsScreen(session: session));
      } else {
        // If session doesn't exist for some reason, just go back
        Get.back(result: {'refresh': true});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving report: $e';
      });

      Get.snackbar(
        'Error',
        'Failed to save report: ${e.toString()}',
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
                    'Error Loading Report',
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
                  widget.reportId == null
                      ? 'New Vehicle Report'
                      : 'Vehicle Report',
              subtitle: _clientName,
              isEditing: _isEditing,
              isSaving: _isSaving,
              onSavePressed: _saveChanges,
              onEditPressed: _toggleEditMode,
              onCancelPressed: widget.reportId == null ? null : _toggleEditMode,
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Date
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Report Date:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.now()),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Client Information Section
                    _buildSectionHeader('Client Information'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _getSectionDecoration(theme),
                      child: Column(
                        children: [
                          // Client name (non-editable)
                          InfoRow(
                            label: 'Name',
                            value: _clientData['name'] ?? '',
                            isEditing: false,
                          ),

                          const SizedBox(height: 12),

                          // Phone (editable)
                          _isEditing
                              ? TextFieldRow(
                                label: 'Phone',
                                controller: _clientPhoneController,
                              )
                              : InfoRow(
                                label: 'Phone',
                                value: _clientPhoneController.text,
                                isEditing: false,
                              ),

                          const SizedBox(height: 12),

                          // City (editable)
                          _isEditing
                              ? TextFieldRow(
                                label: 'City',
                                controller: _clientCityController,
                              )
                              : InfoRow(
                                label: 'City',
                                value: _clientCityController.text,
                                isEditing: false,
                              ),

                          const SizedBox(height: 12),

                          // Country (editable)
                          _isEditing
                              ? TextFieldRow(
                                label: 'Country',
                                controller: _clientCountryController,
                              )
                              : InfoRow(
                                label: 'Country',
                                value: _clientCountryController.text,
                                isEditing: false,
                              ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Car Information Section
                    _buildSectionHeader('Vehicle Information'),
                    const SizedBox(height: 8),
                    Text(
                      _carDetails,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _getSectionDecoration(theme),
                      child: Column(
                        children: [
                          // Make
                          InfoRow(
                            label: 'Make',
                            value: _carData['make'] ?? '',
                            isEditing: false,
                          ),

                          const SizedBox(height: 12),

                          // Model
                          InfoRow(
                            label: 'Model',
                            value: _carData['model'] ?? '',
                            isEditing: false,
                          ),

                          const SizedBox(height: 12),

                          // Year
                          InfoRow(
                            label: 'Year',
                            value:
                                _carData['year'] != null
                                    ? _carData['year'].toString()
                                    : '',
                            isEditing: false,
                          ),

                          const SizedBox(height: 12),

                          // Plate number
                          InfoRow(
                            label: 'Plate Number',
                            value: _carData['plateNumber'] ?? '',
                            isEditing: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Condition Rating
                    _buildSectionHeader('Vehicle Condition Rating'),
                    const SizedBox(height: 12),

                    _isEditing
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) {
                            final rating = index + 1;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _conditionRating = rating;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      rating == _conditionRating
                                          ? theme.primaryColor
                                          : Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        rating == _conditionRating
                                            ? theme.primaryColor
                                            : Colors.grey.withAlpha(77),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  rating.toString(),
                                  style: TextStyle(
                                    color:
                                        rating == _conditionRating
                                            ? Colors.black
                                            : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        )
                        : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _getSectionDecoration(theme),
                          child: Row(
                            children: [
                              Text(
                                'Rating: ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$_conditionRating / 5',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getRatingColor(_conditionRating),
                                ),
                              ),
                              Text(
                                ' (${_getRatingText(_conditionRating)})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                    const SizedBox(height: 8),
                    Text(
                      '1 = Poor, 5 = Excellent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Report Summary
                    _buildSectionHeader('Summary'),
                    const SizedBox(height: 12),
                    _isEditing
                        ? TextField(
                          controller: _summaryController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withAlpha(77),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withAlpha(77),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            hintText:
                                'Enter a summary of the vehicle inspection',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                        : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: _getSectionDecoration(theme),
                          child: Text(
                            _summaryController.text.isNotEmpty
                                ? _summaryController.text
                                : 'No summary provided',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  _summaryController.text.isNotEmpty
                                      ? Colors.white
                                      : Colors.grey[500],
                              fontStyle:
                                  _summaryController.text.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                            ),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Recommendations
                    _buildSectionHeader('Recommendations'),
                    const SizedBox(height: 12),
                    _isEditing
                        ? TextField(
                          controller: _recommendationsController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withAlpha(77),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withAlpha(77),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            hintText:
                                'Enter your recommendations for the vehicle',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                        : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: _getSectionDecoration(theme),
                          child: Text(
                            _recommendationsController.text.isNotEmpty
                                ? _recommendationsController.text
                                : 'No recommendations provided',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  _recommendationsController.text.isNotEmpty
                                      ? Colors.white
                                      : Colors.grey[500],
                              fontStyle:
                                  _recommendationsController.text.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                            ),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Client Notes & Requests Section
                    _buildSectionHeader('Client Notes & Requests', 
                      trailing: _isEditing 
                        ? IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            onPressed: () => _addNewItemDialog('request'),
                            tooltip: 'Add new request',
                          )
                        : null
                    ),
                    const SizedBox(height: 12),

                    // Client Notes
                    if (_clientNotes != null) ...[
                      Text(
                        'Client Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NotesEditorWidget(
                        notes: _clientNotes,
                        isEditing: _isEditing,
                        onEditPressed: _showEditClientNotesDialog,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Client Images
                    _buildImageSection(
                      'Client Images', 
                      _clientNotesImages, 
                      'client', 
                      _isEditing
                    ),

                    // Client Requests
                    const SizedBox(height: 16),
                    Text(
                      'Client Requests',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_clientRequests.isEmpty) 
                      _buildEmptyState('No client requests found'),
                    
                    ..._clientRequests.asMap().entries.map((entry) {
                      final index = entry.key;
                      final request = entry.value;
                      return _buildItemCard(
                        request, 
                        'request', 
                        theme,
                        index: index,
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // Inspection Section
