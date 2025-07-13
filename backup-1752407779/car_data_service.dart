import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class CarDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for makes and models
  List<String>? _cachedMakes;
  final Map<String, List<String>> _cachedModels = {};
  DateTime? _lastMakesFetch;
  final Map<String, DateTime> _lastModelsFetch = {};

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<List<String>> fetchCarMakes() async {
    try {
      // Check if we have cached data that's still fresh
      if (_cachedMakes != null &&
          _lastMakesFetch != null &&
          DateTime.now().difference(_lastMakesFetch!) < _cacheDuration) {
        debugPrint('Returning cached car makes: $_cachedMakes');
        return _cachedMakes!;
      }

      debugPrint('Fetching car makes from Firestore...');
      final snapshot = await _firestore.collection('car_makes').get();
      debugPrint('Found ${snapshot.docs.length} car make documents');
      final makes = snapshot.docs.map((doc) => doc.id).toList();
      makes.sort(); // Sort alphabetically for better UX

      // Cache the results
      _cachedMakes = makes;
      _lastMakesFetch = DateTime.now();

      debugPrint('Car makes: $makes');
      return makes;
    } catch (e) {
      debugPrint('Error in fetchCarMakes: $e');
      return _cachedMakes ?? [];
    }
  }

  Future<List<String>> fetchCarModels(String make) async {
    try {
      // Check if we have cached data that's still fresh
      if (_cachedModels.containsKey(make) &&
          _lastModelsFetch.containsKey(make) &&
          DateTime.now().difference(_lastModelsFetch[make]!) < _cacheDuration) {
        debugPrint('Returning cached models for $make: ${_cachedModels[make]}');
        return _cachedModels[make]!;
      }

      debugPrint('Fetching models for make: $make');
      final doc = await _firestore.collection('car_makes').doc(make).get();
      debugPrint('Document exists: ${doc.exists}');

      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('models')) {
        final models = doc.data()!['models'] as List<dynamic>;
        final modelList = models.cast<String>();
        modelList.sort(); // Sort alphabetically for better UX

        // Cache the results
        _cachedModels[make] = modelList;
        _lastModelsFetch[make] = DateTime.now();

        debugPrint('Models for $make: $modelList');
        return modelList;
      }
      debugPrint('No models found for $make');
      return [];
    } catch (e) {
      debugPrint('Error in fetchCarModels: $e');
      return _cachedModels[make] ?? [];
    }
  }

  Future<void> addCarMakeAndModel(String make, String model) async {
    try {
      debugPrint('Adding make: $make, model: $model to Firestore');
      final docRef = _firestore.collection('car_makes').doc(make);
      final doc = await docRef.get();

      if (doc.exists) {
        final List<dynamic> models = doc.data()!['models'] ?? [];
        if (!models.contains(model)) {
          await docRef.update({
            'models': FieldValue.arrayUnion([model]),
          });
          debugPrint('Added model $model to existing make $make');

          // Update cache
          if (_cachedModels.containsKey(make)) {
            _cachedModels[make]!.add(model);
            _cachedModels[make]!.sort();
          }
        } else {
          debugPrint('Model $model already exists for make $make');
        }
      } else {
        await docRef.set({
          'models': [model],
        });
        debugPrint('Created new make $make with model $model');

        // Update cache
        if (_cachedMakes != null && !_cachedMakes!.contains(make)) {
          _cachedMakes!.add(make);
          _cachedMakes!.sort();
        }
        _cachedModels[make] = [model];
        _lastModelsFetch[make] = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error in addCarMakeAndModel: $e');
    }
  }

  // Method to clear cache if needed
  void clearCache() {
    _cachedMakes = null;
    _cachedModels.clear();
    _lastMakesFetch = null;
    _lastModelsFetch.clear();
  }
}
