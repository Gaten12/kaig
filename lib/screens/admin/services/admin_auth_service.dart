import 'package:cloud_functions/cloud_functions.dart';

class AdminAuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  // Fungsi untuk memicu reset password
  Future<void> resetPassword(String email) async {
    try {
      final callable = _functions.httpsCallable('resetUserPassword');
      final result = await callable.call(<String, dynamic>{
        'email': email,
      });
      print(result.data['message']); // Untuk logging atau notifikasi
    } on FirebaseFunctionsException catch (e) {
      print('Gagal reset password: ${e.code} - ${e.message}');
      throw Exception('Gagal mengirim email reset password. ${e.message}');
    } catch (e) {
      print('Error tidak terduga: $e');
      throw Exception('Terjadi kesalahan tidak terduga.');
    }
  }

  // Fungsi untuk disable/enable akun
  Future<void> toggleAccountStatus(String uid, bool isDisabled) async {
    try {
      final callable = _functions.httpsCallable('toggleUserStatus');
      final result = await callable.call(<String, dynamic>{
        'uid': uid,
        'disabled': isDisabled,
      });
      print(result.data['message']);
    } on FirebaseFunctionsException catch (e) {
      print('Gagal mengubah status akun: ${e.code} - ${e.message}');
      throw Exception('Gagal mengubah status akun. ${e.message}');
    } catch (e) {
      print('Error tidak terduga: $e');
      throw Exception('Terjadi kesalahan tidak terduga.');
    }
  }

  // Fungsi untuk menghapus akun (Authentication & Firestore)
  Future<void> deleteUser(String uid) async {
    try {
      final callable = _functions.httpsCallable('deleteUserAccount');
      final result = await callable.call(<String, dynamic>{
        'uid': uid,
      });
      print(result.data['message']);
    } on FirebaseFunctionsException catch (e) {
      print('Gagal menghapus akun: ${e.code} - ${e.message}');
      throw Exception('Gagal menghapus akun. ${e.message}');
    } catch (e) {
      print('Error tidak terduga: $e');
      throw Exception('Terjadi kesalahan tidak terduga.');
    }
  }
}