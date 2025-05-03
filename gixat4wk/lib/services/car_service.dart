import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import 'session_service.dart';

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

      // Pass all car data to the session
      final sessionId = await _sessionService.createSession(
        clientId: car.clientId,
        clientName: car.clientName, // Pass client name
        clientPhoneNumber: car.clientPhoneNumber, // Pass client phone number
        carId: carId,
        carMake: car.make, // Pass car make
        carModel: car.model, // Pass car model
        plateNumber: car.plateNumber, // Pass plate number
        garageId: car.garageId,
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

  // Get cars for a specific client
  Future<List<Car>> getClientCars(String clientId) async {
    try {
      final snapshot =
          await _carsCollection.where('clientId', isEqualTo: clientId).get();

      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting client cars: $e');
      return [];
    }
  }

  // Get cars for a specific garage
  Future<List<Car>> getGarageCars(String garageId) async {
    try {
      final snapshot =
          await _carsCollection.where('garageId', isEqualTo: garageId).get();

      return snapshot.docs
          .map((doc) => Car.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting garage cars: $e');
      return [];
    }
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

  // Delete a car
  Future<bool> deleteCar(String id) async {
    try {
      await _carsCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting car: $e');
      return false;
    }
  }
}
