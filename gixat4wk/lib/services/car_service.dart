import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/client.dart'; // Added import for Client model
import 'session/session_service.dart';
import 'car_deletion_service.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _carsCollection => _firestore.collection('cars');
  final SessionService _sessionService = SessionService();

  // Add a new car and create session
  Future<Map<String, String>?> addCarAndCreateSession(Car car) async {
    try {
      // Add the car first
      final docRef = await _carsCollection.add(car.toMap());
      final carId = docRef.id;

      // Add the car ID to the client's carsId array
      await _firestore.collection('clients').doc(car.clientId).update({
        'carsId': FieldValue.arrayUnion([carId]),
      });

      // Pass all car data to the session using the enhanced SessionService
      final sessionId = await _sessionService.createSession(
        clientId: car.clientId,
        clientName: car.clientName,
        clientPhoneNumber: car.clientPhoneNumber,
        carId: carId,
        carMake: car.make,
        carModel: car.model,
        plateNumber: car.plateNumber,
        garageId: car.garageId,
        carYear: car.year,
        carVin: car.vin,
      );

      if (sessionId != null) {
        // Update car with new session ID
        final updatedCar = car.addSession(sessionId);
        await _carsCollection.doc(carId).update({
          'sessions': updatedCar.sessions,
        });

        // Add the session ID to the client's sessionsId array
        await _firestore.collection('clients').doc(car.clientId).update({
          'sessionsId': FieldValue.arrayUnion([sessionId]),
        });

        // Return both IDs for next steps
        return {'carId': carId, 'sessionId': sessionId};
      }

      return null;
    } catch (e) {
      debugPrint('Error adding car and creating session: $e');
      return null;
    }
  }

  // Add a new car
  Future<String?> addCar(Car car) async {
    try {
      final docRef = await _carsCollection.add(car.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding car: $e');
      return null;
    }
  }

  // Get a single car by ID
  Future<Car?> getCar(String id) async {
    try {
      final doc = await _carsCollection.doc(id).get();
      if (doc.exists) {
        return Car.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting car: $e');
      return null;
    }
  }

  // Get cars for a specific client (active only by default)
  Future<List<Car>> getClientCars(String clientId, {bool includeDeleted = false}) async {
    try {
      Query query = _carsCollection.where('clientId', isEqualTo: clientId);
      
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }
      
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting client cars: $e');
      return [];
    }
  }

  // Get active cars for a specific client
  Future<List<Car>> getActiveClientCars(String clientId) async {
    try {
      final snapshot = await CarDeletionService.getActiveCarsQuery()
          .where('clientId', isEqualTo: clientId)
          .get();

      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting active client cars: $e');
      return [];
    }
  }

  // Get cars for a specific garage (active only by default)
  Future<List<Car>> getGarageCars(String garageId, {bool includeDeleted = false}) async {
    try {
      Query query = _carsCollection.where('garageId', isEqualTo: garageId);
      
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }
      
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting garage cars: $e');
      return [];
    }
  }

  // Get cars by status
  Future<List<Car>> getCarsByStatus(CarStatus status) async {
    try {
      final carData = await CarDeletionService.getCarsByStatus(status);
      return carData.map((data) => Car.fromMap(data, data['id'])).toList();
    } catch (e) {
      debugPrint('Error getting cars by status: $e');
      return [];
    }
  }

  // Get cars stream with filtering
  Stream<List<Car>> getCarsStream({
    String? clientId,
    String? garageId,
    bool includeDeleted = false,
    bool includeSold = false,
    bool includeTotaled = false,
    CarStatus? filterByStatus,
  }) {
    Query query = _firestore.collection('cars');
    
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    
    if (!includeSold) {
      query = query.where('isSold', isEqualTo: false);
    }
    
    if (!includeTotaled) {
      query = query.where('isTotaled', isEqualTo: false);
    }
    
    if (filterByStatus != null) {
      query = query.where('status', isEqualTo: filterByStatus.name);
    }
    
    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    
    if (garageId != null) {
      query = query.where('garageId', isEqualTo: garageId);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => 
        Car.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    });
  }

  // Update a car
  Future<bool> updateCar(String id, Map<String, dynamic> data) async {
    try {
      await _carsCollection.doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating car: $e');
      return false;
    }
  }

  // Add a session to a car
  Future<bool> addSessionToCar(String carId, String sessionId) async {
    try {
      await _carsCollection.doc(carId).update({
        'sessions': FieldValue.arrayUnion([sessionId]),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding session to car: $e');
      return false;
    }
  }

  // Remove a session from a car
  Future<bool> removeSessionFromCar(String carId, String sessionId) async {
    try {
      await _carsCollection.doc(carId).update({
        'sessions': FieldValue.arrayRemove([sessionId]),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing session from car: $e');
      return false;
    }
  }

  // Soft delete a car (recommended)
  Future<bool> softDeleteCar(String carId, String deletedBy, {String? reason}) async {
    try {
      return await CarDeletionService.softDeleteCar(
        carId: carId,
        deletedBy: deletedBy,
        reason: reason,
        status: CarStatus.deleted,
      );
    } catch (e) {
      debugPrint('Error soft deleting car: $e');
      return false;
    }
  }

  // Hard delete a car (use with caution)
  Future<bool> deleteCar(String id) async {
    try {
      await _carsCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting car: $e');
      return false;
    }
  }

  // Restore a deleted car
  Future<bool> restoreCar(String carId, String restoredBy, {String? reason}) async {
    try {
      return await CarDeletionService.restoreCar(
        carId: carId,
        restoredBy: restoredBy,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error restoring car: $e');
      return false;
    }
  }

  // Update car status
  Future<bool> updateCarStatus(String carId, CarStatus status, String updatedBy, {String? reason}) async {
    try {
      if (status == CarStatus.deleted) {
        return await softDeleteCar(carId, updatedBy, reason: reason);
      } else if (status == CarStatus.active) {
        return await restoreCar(carId, updatedBy, reason: reason);
      } else {
        return await CarDeletionService.softDeleteCar(
          carId: carId,
          deletedBy: updatedBy,
          reason: reason,
          status: status,
        );
      }
    } catch (e) {
      debugPrint('Error updating car status: $e');
      return false;
    }
  }

  // Get client by ID
  Future<dynamic> getClientById(String clientId) async {
    try {
      final doc = await _firestore.collection('clients').doc(clientId).get();
      if (doc.exists) {
        return doc.data() != null ? Client.fromFirestore(doc) : null;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting client by ID: $e');
      return null;
    }
  }
}
