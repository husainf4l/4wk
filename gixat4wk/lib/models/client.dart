import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String? city;
  final String? country;

  Address({this.city, this.country});

  // Create an Address from Firestore data
  factory Address.fromMap(Map<String, dynamic>? data) {
    if (data == null) return Address();

    return Address(city: data['city'], country: data['country']);
  }

  // Convert Address to Firestore data
  Map<String, dynamic> toMap() {
    return {'city': city, 'country': country};
  }

  // Create a copy of Address with updated fields
  Address copyWith({String? city, String? country}) {
    return Address(city: city ?? this.city, country: country ?? this.country);
  }

  @override
  String toString() {
    return 'Address(city: $city, country: $country)';
  }
}

class Client {
  final String id;
  final String name;
  final String phone;
  final Address address;
  final String garageId;
  final List<String> carsId;
  final List<String> sessionsId;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.garageId,
    List<String>? carsId,
    List<String>? sessionsId,
  }) : carsId = carsId ?? [],
       sessionsId = sessionsId ?? [];

  // Create a Client from Firestore document
  factory Client.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Convert the array fields from Firestore
    List<String> carsIdList = [];
    if (data['carsId'] != null) {
      carsIdList = List<String>.from(data['carsId']);
    }

    List<String> sessionsIdList = [];
    if (data['sessionsId'] != null) {
      sessionsIdList = List<String>.from(data['sessionsId']);
    }

    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: Address.fromMap(data['address'] as Map<String, dynamic>?),
      garageId: data['garageId'] ?? '',
      carsId: carsIdList,
      sessionsId: sessionsIdList,
    );
  }

  // Convert Client to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'address': address.toMap(),
      'garageId': garageId,
      'carsId': carsId,
      'sessionsId': sessionsId,
    };
  }

  // Create a copy of Client with updated fields
  Client copyWith({
    String? name,
    String? phone,
    Address? address,
    String? garageId,
    List<String>? carsId,
    List<String>? sessionsId,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      garageId: garageId ?? this.garageId,
      carsId: carsId ?? this.carsId,
      sessionsId: sessionsId ?? this.sessionsId,
    );
  }

  // Create an empty client
  factory Client.empty() {
    return Client(
      id: '',
      name: '',
      phone: '',
      address: Address(),
      garageId: '',
    );
  }

  // Check if client is empty
  bool get isEmpty => id.isEmpty;

  // Check if client is not empty
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'Client(id: $id, name: $name, phone: $phone, garageId: $garageId)';
  }
}
