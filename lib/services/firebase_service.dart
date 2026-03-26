import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  Future<String> saveUserEquipment(Map<String, dynamic> data) async {
    if (_uid == null) return '';
    final ref = await _userDoc.collection('equipment').add(data);
    return ref.id;
  }

  Future<void> deleteUserEquipment(String equipmentId) async {
    if (_uid == null) return;
    await _userDoc.collection('equipment').doc(equipmentId).delete();
  }

  Future<void> updateUserEquipment(
      String equipmentId, Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _userDoc
        .collection('equipment')
        .doc(equipmentId)
        .update(data);
  }

  Future<Map<String, dynamic>?> getWorkScheduleConfig() async {
    final doc = await _firestore
        .collection('config')
        .doc('workSchedule')
        .get();
    return doc.data();
  }

  Future<void> saveWorkScheduleConfig(Map<String, dynamic> config) async {
    await _firestore
        .collection('config')
        .doc('workSchedule')
        .set(config);
  }

  Future<void> generateScheduleFromConfig(
    Map<String, dynamic> config,
    int weeksAhead,
  ) async {
    final workDays = (config['workDays'] as List?)?.cast<int>() ?? [];
    final startHour = config['startHour'] as int? ?? 9;
    final endHour = config['endHour'] as int? ?? 18;

    final slots = <String>[];
    for (var h = startHour; h < endHour; h++) {
      slots.add(
          '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00');
    }

    final now = DateTime.now();
    final batch = _firestore.batch();
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var d = 1; d <= weeksAhead * 7; d++) {
      final date = now.add(Duration(days: d));
      if (!workDays.contains(date.weekday)) continue;

      final key = dateFormat.format(date);
      final existing = await _firestore.collection('schedule').doc(key).get();
      if (existing.exists) continue;

      batch.set(
        _firestore.collection('schedule').doc(key),
        {'slots': slots},
      );
    }

    await batch.commit();
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

  Future<Set<String>> getBookedSlots() async {
    final snap = await _firestore.collection('bookedSlots').get();
    final booked = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final slot = data['slot'] as String?;
      if (date != null && slot != null) {
        booked.add('$date|$slot');
      }
    }
    return booked;
  }

  Future<bool> bookSlotsAtomically(
    String date,
    List<String> slots,
  ) async {
    return _firestore.runTransaction((transaction) async {
      final schedRef = _firestore.collection('schedule').doc(date);
      final schedSnap = await transaction.get(schedRef);

      if (!schedSnap.exists) return false;

      final available =
          (schedSnap.data()?['slots'] as List?)?.cast<String>() ?? [];

      for (final slot in slots) {
        if (!available.contains(slot)) return false;
      }

      final remaining = [...available];
      for (final slot in slots) {
        remaining.remove(slot);
      }

      if (remaining.isEmpty) {
        transaction.delete(schedRef);
      } else {
        transaction.update(schedRef, {'slots': remaining});
      }

      for (final slot in slots) {
        final bookedRef = _firestore.collection('bookedSlots').doc();
        transaction.set(bookedRef, {
          'date': date,
          'slot': slot,
          'userId': _uid,
          'bookedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    });
  }

  Future<void> cancelBookedSlot(String date, String slot) async {
    final snap = await _firestore
        .collection('bookedSlots')
        .where('date', isEqualTo: date)
        .where('slot', isEqualTo: slot)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<Map<String, dynamic>>> getEquipmentBrands() async {
    final snap = await _firestore
        .collection('equipmentCatalog')
        .orderBy('order')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getQuoteCatalog() async {
    final snap = await _firestore
        .collection('quoteCatalog')
        .orderBy('brand')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<String>> getEquipmentTypes() async {
    final doc =
        await _firestore.collection('config').doc('equipmentTypes').get();
    final data = doc.data();
    if (data != null && data['types'] is List) {
      return (data['types'] as List).cast<String>();
    }
    return [];
  }

  Future<void> createGlobalAppointment(Map<String, dynamic> data) async {
    await _firestore.collection('appointments').add(data);
  }

  Future<Map<String, dynamic>?> getPricingConfig() async {
    final doc =
        await _firestore.collection('config').doc('pricing').get();
    return doc.data();
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
