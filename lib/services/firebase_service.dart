import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:alx_clima/models/customer_profile.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _firestore.collection('users').doc(_uid);
  }

  Future<Map<String, dynamic>?> getCompanyInfo() async {
    final doc = await _firestore.collection('company').doc('info').get();
    return doc.data();
  }

  Future<CustomerProfile?> getUserProfile() async {
    if (_uid == null) return null;
    final doc = await _userDoc.get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerProfile.fromMap(doc.data()!);
  }

  Future<void> saveUserProfile(CustomerProfile profile) async {
    if (_uid == null) return;
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> createUserDocument(String name, String email) async {
    if (_uid == null) return;
    final profile = CustomerProfile(
      name: name,
      phone: '',
      email: email,
    );
    await _userDoc.set(profile.toMap());
  }

  Future<Map<String, List<String>>> getAvailableSlots() async {
    final snap = await _firestore.collection('schedule').get();
    final result = <String, List<String>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final slots = data['slots'];
      if (slots is List) {
        result[doc.id] = slots.cast<String>();
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (_uid == null) return {};
    final equipmentSnap =
        await _userDoc.collection('equipment').get();
    final servicesSnap =
        await _userDoc.collection('serviceHistory').get();
    final userDoc = await _userDoc.get();
    final data = userDoc.data();
    DateTime? memberSince;
    if (data != null && data['memberSince'] is Timestamp) {
      memberSince = (data['memberSince'] as Timestamp).toDate();
    }
    return {
      'equipmentCount': equipmentSnap.docs.length,
      'servicesCount': servicesSnap.docs.length,
      'memberSince': memberSince,
    };
  }
}
