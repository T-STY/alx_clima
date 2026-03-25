import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerProfile {
  final String name;
  final String phone;
  final String? email;
  final String? street;
  final String? exteriorNumber;
  final String? interiorNumber;
  final String? colonia;
  final String? city;
  final String? postalCode;
  final String? state;
  final String? notes;
  final DateTime? memberSince;

  const CustomerProfile({
    required this.name,
    required this.phone,
    this.email,
    this.street,
    this.exteriorNumber,
    this.interiorNumber,
    this.colonia,
    this.city,
    this.postalCode,
    this.state,
    this.notes,
    this.memberSince,
  });

  String get displayAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) {
      var streetLine = street!;
      if (exteriorNumber != null && exteriorNumber!.isNotEmpty) {
        streetLine += ' #$exteriorNumber';
      }
      if (interiorNumber != null && interiorNumber!.isNotEmpty) {
        streetLine += ', Int. $interiorNumber';
      }
      parts.add(streetLine);
    }
    if (colonia != null && colonia!.isNotEmpty) {
      parts.add('Col. $colonia');
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }
    if (postalCode != null && postalCode!.isNotEmpty) {
      parts.add('C.P. $postalCode');
    }
    return parts.join(', ');
  }

  CustomerProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? street,
    String? exteriorNumber,
    String? interiorNumber,
    String? colonia,
    String? city,
    String? postalCode,
    String? state,
    String? notes,
    DateTime? memberSince,
  }) {
    return CustomerProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      street: street ?? this.street,
      exteriorNumber: exteriorNumber ?? this.exteriorNumber,
      interiorNumber: interiorNumber ?? this.interiorNumber,
      colonia: colonia ?? this.colonia,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      memberSince: memberSince ?? this.memberSince,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'street': street,
      'exteriorNumber': exteriorNumber,
      'interiorNumber': interiorNumber,
      'colonia': colonia,
      'city': city,
      'postalCode': postalCode,
      'state': state,
      'notes': notes,
      'memberSince': memberSince != null
          ? Timestamp.fromDate(memberSince!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory CustomerProfile.fromMap(Map<String, dynamic> map) {
    return CustomerProfile(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      street: map['street'],
      exteriorNumber: map['exteriorNumber'],
      interiorNumber: map['interiorNumber'],
      colonia: map['colonia'],
      city: map['city'],
      postalCode: map['postalCode'],
      state: map['state'],
      notes: map['notes'],
      memberSince: map['memberSince'] is Timestamp
          ? (map['memberSince'] as Timestamp).toDate()
          : null,
    );
  }
}
