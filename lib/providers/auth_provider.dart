import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:alx_clima/services/auth_service.dart';
import 'package:alx_clima/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  User? _user;
  bool _isLoading = true;
  bool _isSuspended = false;
  String? _error;
  StreamSubscription? _suspensionSub;
  StreamSubscription? _notificationSub;
  List<Map<String, dynamic>> _notifications = [];

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _suspensionSub?.cancel();
    _notificationSub?.cancel();
    super.dispose();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null && !_isSuspended;
  bool get isSuspended => _isSuspended;
  String? get error => _error;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationCount =>
      _notifications.where((n) => n['read'] != true).length;

  void _onAuthStateChanged(User? user) {
    _suspensionSub?.cancel();
    _notificationSub?.cancel();
    _user = user;
    _isSuspended = false;
    _notifications = [];
    _isLoading = false;

    if (user != null) {
      _listenToSuspension(user.uid);
      _listenToNotifications(user.uid);
    }

    notifyListeners();
  }

  void _listenToSuspension(String uid) {
    _suspensionSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final suspended = data?['suspended'] == true;
      if (suspended != _isSuspended) {
        _isSuspended = suspended;
        notifyListeners();
      }
    });
  }

  void _listenToNotifications(String uid) {
    _notificationSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
      notifyListeners();
    });
  }

  Future<void> markNotificationRead(String docId) async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('notifications')
        .doc(docId)
        .update({'read': true});
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final credential =
          await _authService.signUpWithEmail(email, password);
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await _firebaseService.createUserDocument(name, email);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> resetPassword(String email) async {
    _error = null;
    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña';
      default:
        return 'Ocurrió un error. Intenta de nuevo';
    }
  }
}
