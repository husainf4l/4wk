import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/client.dart';
import 'error_service.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get error service for error logging
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  // Collection reference
  CollectionReference get _clientsCollection =>
      _firestore.collection('clients');

  // Get all clients for a garage
  Stream<List<Client>> getClientsForGarage(String garageId) {
    return _clientsCollection
        .where('garageId', isEqualTo: garageId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
        });
  }

  // Get a single client by ID
  Future<Client?> getClientById(String clientId) async {
    try {
      DocumentSnapshot doc = await _clientsCollection.doc(clientId).get();
      if (doc.exists) {
        return Client.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.getClientById',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Add a new client
  Future<String?> addClient(Client client) async {
    try {
      DocumentReference docRef = await _clientsCollection.add(
        client.toFirestore(),
      );
      return docRef.id;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.addClient',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Update an existing client
  Future<bool> updateClient(Client client) async {
    try {
      await _clientsCollection.doc(client.id).update(client.toFirestore());
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.updateClient',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Delete a client
  Future<bool> deleteClient(String clientId) async {
    try {
      await _clientsCollection.doc(clientId).delete();
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.deleteClient',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Add a car ID to a client
  Future<bool> addCarToClient(String clientId, String carId) async {
    try {
      await _clientsCollection.doc(clientId).update({
        'carsId': FieldValue.arrayUnion([carId]),
      });
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.addCarToClient',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Add a session ID to a client
  Future<bool> addSessionToClient(String clientId, String sessionId) async {
    try {
      await _clientsCollection.doc(clientId).update({
        'sessionsId': FieldValue.arrayUnion([sessionId]),
      });
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientService.addSessionToClient',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
