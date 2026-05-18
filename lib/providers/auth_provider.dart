import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final UserModel _user = UserModel(
    id: "standalone_user_id",
    name: "Developer Admin",
    email: "standalone@streamo.local",
    tier: SubscriptionTier.pro,
  );

  bool get isLoading => false;
  bool get isAuthenticated => true;

  // Provide both user and currentUser getters for compiling compatibility
  UserModel? get user => _user;
  UserModel? get currentUser => _user;

  AuthProvider() {
    // Standalone login-free initialization
  }

  Future<bool> login(String email, String password) async {
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    return true;
  }

  Future<Map<String, dynamic>> checkDownloadLimit() async {
    return {
      'allowed': true,
      'remaining': 'Unlimited',
    };
  }

  Future<void> recordDownload(String videoId) async {
    // No-op locally
  }

  Future<void> upgradeToPro() async {
    // Standalone mock is already PRO!
  }

  Future<void> logout() async {
    // No-op locally
  }
}
