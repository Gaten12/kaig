// lib/src/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // UID dari Firebase Auth
  final String email;
  final String noTelepon;
  final String role;
  final Timestamp createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.noTelepon,
    required this.role,
    required this.createdAt,
  });

  // Factory constructor untuk membuat instance UserModel dari Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("User data is null!"); // Atau handle dengan cara lain
    }
    return UserModel(
      id: snapshot.id,
      email: data['email'] as String? ?? '', // Beri nilai default jika null
      noTelepon: data['no_telepon'] as String? ?? '',
      role: data['role'] as String? ?? 'costumer', // Default role jika tidak ada
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Default jika tidak ada
    );
  }

  // Method untuk mengubah instance UserModel menjadi Map<String, dynamic> untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'no_telepon': noTelepon,
      'role': role,
      'createdAt': createdAt, // Firebase akan handle jika ini FieldValue.serverTimestamp() saat penulisan awal
    };
  }
}