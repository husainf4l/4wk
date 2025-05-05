import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../models/session.dart';
import '../../services/report_service.dart';
import '../../widgets/detail_screen_header.dart';
import '../../widgets/notes_editor_widget.dart';
import '../sessions/session_details_screen.dart';
import '../../widgets/report/image_manager_sheet.dart';
import '../../widgets/report/requests_editor_sheet.dart';
import '../../widgets/report/info_widgets.dart';
import '../../widgets/report/report_section_widget.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String sessionId;
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
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _recommendationsController =
      TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientCityController = TextEditingController();
  final TextEditingController _clientCountryController =
      TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isGeneratingAI = false;
  String? _errorMessage;
  String _reportPassword = ''; // Password for report access

  // Session data
  Session? _session;

  // Generate a random 5-letter password
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

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

  // Mileage information
  String? _mileage;

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

            // Load password from the report
            _reportPassword = reportData['password'] ?? '';

            // Set other report fields
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
              _testDriveImages = List<String>.from(
                reportData['testDriveImages'],
              );
            }
          });
          return;
        }
      }

      // If no existing report or failed to load, gather data from source records
      await _loadClientNotesData();
      await _loadInspectionData();
      await _loadTestDriveData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading report data: $e';
      });
    }
  }

  // Helper methods for loading data from individual sources
  Future<void> _loadClientNotesData() async {
    if (_session?.clientNoteId == null) return;

    final clientNotesData = await _reportService.getClientNotes(
      _session!.clientNoteId!,
    );
    if (clientNotesData != null) {
      setState(() {
        _clientNotes = clientNotesData['notes'];

        // Load mileage from client notes if available
        if (clientNotesData['mileage'] != null) {
          _mileage = clientNotesData['mileage'];
        }

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

  Future<void> _loadInspectionData() async {
    if (_session?.inspectionId == null) return;

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

  Future<void> _loadTestDriveData() async {
    if (_session?.testDriveId == null) return;

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

  Future<void> _saveChanges() async {
    if (!mounted) return;

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

      // If creating a new report, generate a random password
      if (widget.reportId == null) {
        _reportPassword = _generateRandomPassword();
      }

      // Create report data
      final Map<String, dynamic> reportData = {
        'summary': _summaryController.text,
        'recommendations': _recommendationsController.text,
        'clientNotes': _clientNotes,
        'inspectionNotes': _inspectionNotes,
        'testDriveNotes': _testDriveNotes,
        'clientRequests': _clientRequests,
        'inspectionFindings': _inspectionFindings,
        'testDriveObservations': _testDriveObservations,
        'clientNotesImages': _clientNotesImages,
        'inspectionImages': _inspectionImages,
        'testDriveImages': _testDriveImages,
        'password': _reportPassword, // Add the password to the report data
        'mileage': _mileage, // Include mileage in the report data
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

      // Navigate back to the session details screen with updated session data
      final sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc(widget.sessionId)
              .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data() as Map<String, dynamic>;
        final session = Session.fromMap(sessionData, widget.sessionId);
        Get.off(() => SessionDetailsScreen(session: session));
      } else {
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

  // Generate AI summary and recommendations
  Future<void> _generateAIContent() async {
    // Make sure we have a reportId
    if (widget.reportId == null) {
      Get.snackbar(
        'Error',
        'Please save the report first before generating AI content',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isGeneratingAI = true;
    });

    try {
      // Call the API to generate AI content
      final result = await _reportService.generateAIContent(widget.reportId!);

      // Since AI content updates Firebase directly, we need to re-fetch the updated report
      final updatedReportData = await _reportService.getReport(
        widget.reportId!,
      );

      if (updatedReportData != null) {
        setState(() {
          // Update from Firebase data
          if (updatedReportData['summary'] != null) {
            _summaryController.text = updatedReportData['summary'];
          }

          if (updatedReportData['recommendations'] != null) {
            _recommendationsController.text =
                updatedReportData['recommendations'];
          }
        });

        Get.snackbar(
          'Success',
          'AI content generated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Fall back to using result from API if re-fetch fails
        // Check for the correct response format where data is nested in a 'data' field
        bool hasContent = false;

        if (result.containsKey('success') &&
            result['success'] == true &&
            result.containsKey('data')) {
          final data = result['data'] as Map<String, dynamic>;
          setState(() {
            if (data.containsKey('summary')) {
              _summaryController.text = data['summary'];
              hasContent = true;
            }

            if (data.containsKey('recommendations')) {
              _recommendationsController.text = data['recommendations'];
              hasContent = true;
            }
          });
        } else if (result.containsKey('summary') ||
            result.containsKey('recommendations')) {
          // Legacy format handling for backward compatibility
          setState(() {
            if (result.containsKey('summary')) {
              _summaryController.text = result['summary'];
              hasContent = true;
            }

            if (result.containsKey('recommendations')) {
              _recommendationsController.text = result['recommendations'];
              hasContent = true;
            }
          });
        }

        if (hasContent) {
          Get.snackbar(
            'Success',
            'AI content generated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Notice',
            'No AI content was generated',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber,
            colorText: Colors.black,
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating AI content: $e');
      Get.snackbar(
        'Error',
        'Failed to generate AI content: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isGeneratingAI = false;
      });
    }
  }

  // Show the requests editor sheet
  void _showEditRequestsDialog(String section) {
    List<Map<String, dynamic>> items = [];
    late Function(List<Map<String, dynamic>>) updateFunction;
    String title = '';
    String itemType = '';
    String fieldName = '';

    switch (section) {
      case 'client':
        items = List.from(_clientRequests);
        updateFunction = (items) => setState(() => _clientRequests = items);
        title = 'Client Service Requests';
        itemType = 'request';
        fieldName = 'request';
        break;
      case 'inspection':
        items = List.from(_inspectionFindings);
        updateFunction = (items) => setState(() => _inspectionFindings = items);
        title = 'Inspection Findings';
        itemType = 'finding';
        fieldName = 'finding';
        break;
      case 'testdrive':
        items = List.from(_testDriveObservations);
        updateFunction =
            (items) => setState(() => _testDriveObservations = items);
        title = 'Test Drive Observations';
        itemType = 'observation';
        fieldName = 'observation';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RequestsEditorSheet(
          title: title,
          items: items,
          itemType: itemType,
          fieldName: fieldName,
          onUpdate: updateFunction,
        );
      },
    );
  }

  // Add a new request item
  void _addNewRequest(String section) {
    Map<String, dynamic> newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'argancy': 'low',
      'price': 0,
      'visible': true,
    };

    switch (section) {
      case 'client':
        newItem['request'] = '';
        _showEditRequestDialog(
          newItem,
          'request',
          (item) => setState(() => _clientRequests.add(item)),
        );
        break;
      case 'inspection':
        newItem['finding'] = '';
        _showEditRequestDialog(
          newItem,
          'finding',
          (item) => setState(() => _inspectionFindings.add(item)),
        );
        break;
      case 'testdrive':
        newItem['observation'] = '';
        _showEditRequestDialog(
          newItem,
          'observation',
          (item) => setState(() => _testDriveObservations.add(item)),
        );
        break;
    }
  }

  // Edit an existing request item
  void _editRequest(Map<String, dynamic> item, String section) {
    String fieldName;
    Function(Map<String, dynamic>) updateFunction;

    switch (section) {
      case 'client':
        fieldName = 'request';
        updateFunction = (updatedItem) {
          setState(() {
            final index = _clientRequests.indexWhere(
              (r) => r['id'] == item['id'],
            );
            if (index != -1) {
              _clientRequests[index] = updatedItem;
            }
          });
        };
        break;
      case 'inspection':
        fieldName = 'finding';
        updateFunction = (updatedItem) {
          setState(() {
            final index = _inspectionFindings.indexWhere(
              (f) => f['id'] == item['id'],
            );
            if (index != -1) {
              _inspectionFindings[index] = updatedItem;
            }
          });
        };
        break;
      case 'testdrive':
        fieldName = 'observation';
        updateFunction = (updatedItem) {
          setState(() {
            final index = _testDriveObservations.indexWhere(
              (o) => o['id'] == item['id'],
            );
            if (index != -1) {
              _testDriveObservations[index] = updatedItem;
            }
          });
        };
        break;
      default:
        return;
    }

    _showEditRequestDialog(item, fieldName, updateFunction);
  }

  // Show dialog to edit a request item
  void _showEditRequestDialog(
    Map<String, dynamic> item,
    String itemKey,
    Function(Map<String, dynamic>) updateFunction,
  ) {
    final TextEditingController textController = TextEditingController(
      text: item[itemKey] ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: (item['price'] ?? 0).toString(),
    );
    String currentUrgency = item['argancy'] ?? 'low';
    bool isVisible = item['visible'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Edit ${itemKey[0].toUpperCase() + itemKey.substring(1)}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description field
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Price (AED)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgency selector
                    Text(
                      'Urgency Level',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildUrgencyOption(
                          'Low',
                          Colors.green,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                        _buildUrgencyOption(
                          'Medium',
                          Colors.orange,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                        _buildUrgencyOption(
                          'High',
                          Colors.red,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visibility toggle
                    Row(
                      children: [
                        Text(
                          'Visible in Report',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const Spacer(),
                        Switch(
                          value: isVisible,
                          onChanged:
                              (value) =>
                                  setDialogState(() => isVisible = value),
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedItem = Map<String, dynamic>.from(item);
                    updatedItem[itemKey] = textController.text;
                    updatedItem['argancy'] = currentUrgency;
                    updatedItem['price'] =
                        int.tryParse(priceController.text) ?? 0;
                    updatedItem['visible'] = isVisible;

                    updateFunction(updatedItem);
                    Navigator.of(context).pop();
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete a request item
  void _deleteRequest(Map<String, dynamic> item, String section) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text('Delete Item'),
            content: const Text(
              'Are you sure you want to delete this item? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    switch (section) {
                      case 'client':
                        _clientRequests.removeWhere(
                          (r) => r['id'] == item['id'],
                        );
                        break;
                      case 'inspection':
                        _inspectionFindings.removeWhere(
                          (f) => f['id'] == item['id'],
                        );
                        break;
                      case 'testdrive':
                        _testDriveObservations.removeWhere(
                          (o) => o['id'] == item['id'],
                        );
                        break;
                    }
                  });
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  // Manage images for a section
  void _manageImages(String section) {
    List<String> images;
    Function(List<String>) updateFunction;
    String title;

    switch (section) {
      case 'client':
        images = List.from(_clientNotesImages);
        updateFunction =
            (newList) => setState(() => _clientNotesImages = newList);
        title = 'Client Notes Images';
        break;
      case 'inspection':
        images = List.from(_inspectionImages);
        updateFunction =
            (newList) => setState(() => _inspectionImages = newList);
        title = 'Inspection Images';
        break;
      case 'testdrive':
        images = List.from(_testDriveImages);
        updateFunction =
            (newList) => setState(() => _testDriveImages = newList);
        title = 'Test Drive Images';
        break;
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ImageManagerSheet(
          title: title,
          images: images,
          onUpdate: updateFunction,
        );
      },
    );
  }

  // Widget for urgency option selection in dialog
  Widget _buildUrgencyOption(
    String label,
    Color color,
    String currentValue,
    Function(String) onChanged,
  ) {
    final isSelected = currentValue.toLowerCase() == label.toLowerCase();

    return InkWell(
      onTap: () => onChanged(label.toLowerCase()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(77) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Method to share the report via WhatsApp
  void _shareViaWhatsApp() async {
    if (widget.reportId == null) {
      Get.snackbar(
        'Error',
        'Please save the report first before sharing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final clientPhone = _clientPhoneController.text.trim();
    if (clientPhone.isEmpty) {
      Get.snackbar(
        'Error',
        'Client phone number is required for sharing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Format the message text, including the password
    String messageText =
        'You can find your initial car report at this link 4wk.ae/report/${widget.reportId}\n\nYour password is: $_reportPassword';

    // Format the phone number - remove any non-digit characters
    String formattedPhone = clientPhone.replaceAll(RegExp(r'\D'), '');

    // Copy message to clipboard for easier sharing
    await Clipboard.setData(ClipboardData(text: messageText));

    debugPrint("Sharing to WhatsApp: $formattedPhone");
    debugPrint("Message: $messageText");

    try {
      // Encode the message text properly for URLs
      String encodedMessage = Uri.encodeComponent(messageText);

      // Try different URL formats that include the message parameter
      List<Uri> uriToTry = [
        // Intent URI with both phone and text (works on many Android devices)
        Uri.parse("whatsapp://send?phone=$formattedPhone&text=$encodedMessage"),

        // Web URL with both phone and text
        Uri.parse("https://wa.me/$formattedPhone?text=$encodedMessage"),

        // API URL with both phone and text
        Uri.parse(
          "https://api.whatsapp.com/send?phone=$formattedPhone&text=$encodedMessage",
        ),
      ];

      bool launched = false;
      String attemptsLog = "";

      // Try each URI in sequence until one works
      for (var i = 0; i < uriToTry.length; i++) {
        Uri uri = uriToTry[i];
        attemptsLog += "Attempt ${i + 1}: ${uri.toString()}\n";

        if (await canLaunchUrl(uri)) {
          debugPrint("Trying to launch: ${uri.toString()}");
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (launched) {
            debugPrint("Successfully launched: ${uri.toString()}");
            break;
          }
        }
      }

      // If we couldn't launch with the message parameter, try just opening WhatsApp with the phone number
      if (!launched) {
        debugPrint(
          "All attempts with message parameter failed. Trying just the phone number.",
        );
        Uri basicUri = Uri.parse("whatsapp://send?phone=$formattedPhone");

        if (await canLaunchUrl(basicUri)) {
          launched = await launchUrl(basicUri);
        }
      }

      if (launched) {
        Get.snackbar(
          'WhatsApp Opened',
          'If the message is not pre-filled, it has been copied to your clipboard - just paste it in the chat.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 7),
        );
      } else {
        // Log all our attempts for debugging
        debugPrint("Failed to launch WhatsApp. Attempted URLs:\n$attemptsLog");

        Get.snackbar(
          'Error',
          'Could not open WhatsApp. Make sure WhatsApp is installed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');

      // Show error message but also help the user manually share
      Get.dialog(
        AlertDialog(
          title: const Text('WhatsApp Not Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not open WhatsApp automatically (Error: ${e.toString().split('\n').first})',
              ),
              const SizedBox(height: 16),
              const Text(
                'The report link and password have been copied to your clipboard. You can manually:',
              ),
              const SizedBox(height: 8),
              const Text('1. Open WhatsApp'),
              const Text('2. Find the client contact'),
              const Text('3. Paste the message'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingScreen(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(theme);
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
              shareAction: !_isEditing ? _shareViaWhatsApp : null,
            ),

            // Main content
            Expanded(child: _buildMainContent(theme)),
          ],
        ),
      ),
    );
  }

  // Helper methods for building UI components
  Widget _buildLoadingScreen(ThemeData theme) {
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

  Widget _buildErrorScreen(ThemeData theme) {
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

  Widget _buildMainContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Date
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Client Information Section
          _buildClientInfoSection(),

          const SizedBox(height: 24),

          // Car Information Section
          _buildCarInfoSection(),

          // Display Car Details
          const SizedBox(height: 16),
          Text(
            'Car Details: $_carDetails',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),

          const SizedBox(height: 24),

          // Report Summary
          _buildReportSummarySection(theme),

          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendationsSection(theme),

          const SizedBox(height: 24),

          // Client Requests section
          RequestsSectionWidget(
            title: 'Client Service Requests',
            section: 'client',
            items: _clientRequests,
            fieldName: 'request',
            isEditing: _isEditing,
            onEditAll: () => _showEditRequestsDialog('client'),
            onAddNew: () => _addNewRequest('client'),
            onEdit: (item) => _editRequest(item, 'client'),
            onDelete: (item) => _deleteRequest(item, 'client'),
          ),

          // Client Notes Section
          const SizedBox(height: 24),
          NotesSectionWidget(
            title: 'Client Notes',
            notes: _clientNotes,
            isEditing: _isEditing,
            onEdit: _showEditClientNotesDialog,
          ),

          // Client Notes Images
          if (_isEditing || _clientNotesImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ImagesSectionWidget(
              title: 'Client Notes Images',
              section: 'client',
              images: _clientNotesImages,
              isEditing: _isEditing,
              onManageImages: () => _manageImages('client'),
              onRemoveImage:
                  _isEditing
                      ? (index) =>
                          setState(() => _clientNotesImages.removeAt(index))
                      : null,
            ),
          ],

          // Inspection Findings section
          const SizedBox(height: 24),
          RequestsSectionWidget(
            title: 'Inspection Findings',
            section: 'inspection',
            items: _inspectionFindings,
            fieldName: 'finding',
            isEditing: _isEditing,
            onEditAll: () => _showEditRequestsDialog('inspection'),
            onAddNew: () => _addNewRequest('inspection'),
            onEdit: (item) => _editRequest(item, 'inspection'),
            onDelete: (item) => _deleteRequest(item, 'inspection'),
          ),

          // Inspection Notes Section
          const SizedBox(height: 24),
          NotesSectionWidget(
            title: 'Inspection Notes',
            notes: _inspectionNotes,
            isEditing: _isEditing,
            onEdit: _showEditInspectionNotesDialog,
          ),

          // Inspection Images
          if (_isEditing || _inspectionImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ImagesSectionWidget(
              title: 'Inspection Images',
              section: 'inspection',
              images: _inspectionImages,
              isEditing: _isEditing,
              onManageImages: () => _manageImages('inspection'),
              onRemoveImage:
                  _isEditing
                      ? (index) =>
                          setState(() => _inspectionImages.removeAt(index))
                      : null,
            ),
          ],

          // Test Drive Observations section
          const SizedBox(height: 24),
          RequestsSectionWidget(
            title: 'Test Drive Observations',
            section: 'testdrive',
            items: _testDriveObservations,
            fieldName: 'observation',
            isEditing: _isEditing,
            onEditAll: () => _showEditRequestsDialog('testdrive'),
            onAddNew: () => _addNewRequest('testdrive'),
            onEdit: (item) => _editRequest(item, 'testdrive'),
            onDelete: (item) => _deleteRequest(item, 'testdrive'),
          ),

          // Test Drive Notes Section
          const SizedBox(height: 24),
          NotesSectionWidget(
            title: 'Test Drive Notes',
            notes: _testDriveNotes,
            isEditing: _isEditing,
            onEdit: _showEditTestDriveNotesDialog,
          ),

          // Test Drive Images
          if (_isEditing || _testDriveImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ImagesSectionWidget(
              title: 'Test Drive Images',
              section: 'testdrive',
              images: _testDriveImages,
              isEditing: _isEditing,
              onManageImages: () => _manageImages('testdrive'),
              onRemoveImage:
                  _isEditing
                      ? (index) =>
                          setState(() => _testDriveImages.removeAt(index))
                      : null,
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Section builder methods
  Widget _buildClientInfoSection() {
    return ReportSectionWidget(
      title: 'Client Information',
      child: Column(
        children: [
          InfoRow(label: 'Name', value: _clientName),
          const SizedBox(height: 8),
          _isEditing
              ? TextFieldRow(
                label: 'Phone',
                controller: _clientPhoneController,
                keyboardType: TextInputType.phone,
              )
              : InfoRow(label: 'Phone', value: _clientPhoneController.text),
          const SizedBox(height: 8),
          _isEditing
              ? Column(
                children: [
                  TextFieldRow(
                    label: 'City',
                    controller: _clientCityController,
                  ),
                  const SizedBox(height: 8),
                  TextFieldRow(
                    label: 'Country',
                    controller: _clientCountryController,
                  ),
                ],
              )
              : Column(
                children: [
                  InfoRow(label: 'City', value: _clientCityController.text),
                  const SizedBox(height: 8),
                  InfoRow(
                    label: 'Country',
                    value: _clientCountryController.text,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildCarInfoSection() {
    return ReportSectionWidget(
      title: 'Vehicle Information',
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_carData['make'] != null)
            InfoRow(label: 'Make', value: _carData['make']),
          if (_carData['model'] != null) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'Model', value: _carData['model']),
          ],
          if (_carData['year'] != null) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'Year', value: _carData['year'].toString()),
          ],
          if (_carData['plateNumber'] != null) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'Plate', value: _carData['plateNumber']),
          ],
          if (_carData['vin'] != null) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'VIN', value: _carData['vin']),
          ],
          if (_mileage != null && _mileage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'Mileage', value: '$_mileage km'),
          ],
        ],
      ),
    );
  }

  Widget _buildReportSummarySection(ThemeData theme) {
    return ReportSectionWidget(
      title: 'Summary',
      padding: const EdgeInsets.all(16),
      actions:
          _isEditing
              ? [
                IconButton(
                  icon: Icon(
                    Icons.auto_awesome,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Generate AI Summary',
                  onPressed: _isGeneratingAI ? null : _generateAIContent,
                ),
              ]
              : null,
      child:
          _isEditing
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isGeneratingAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generating AI content...',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _summaryController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(77),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(77),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      hintText: 'Enter a summary of the vehicle inspection',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              )
              : Text(
                _summaryController.text.isNotEmpty
                    ? _summaryController.text
                    : 'No summary provided',
                style: TextStyle(
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
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    return ReportSectionWidget(
      title: 'Recommendations',
      padding: const EdgeInsets.all(16),
      actions:
          _isEditing
              ? [
                IconButton(
                  icon: Icon(
                    Icons.auto_awesome,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Generate AI Recommendations',
                  onPressed: _isGeneratingAI ? null : _generateAIContent,
                ),
              ]
              : null,
      child:
          _isEditing
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isGeneratingAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Generating AI content...',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _recommendationsController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(77),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(77),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      hintText: 'Enter your recommendations for the vehicle',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              )
              : Text(
                _recommendationsController.text.isNotEmpty
                    ? _recommendationsController.text
                    : 'No recommendations provided',
                style: TextStyle(
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
    );
  }
}
