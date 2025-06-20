import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeminiCloudFunctionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> sendMessage(String prompt) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final HttpsCallable callable = _functions.httpsCallable('chatWithGemini');
      final HttpsCallableResult result = await callable.call({
        'prompt': prompt,
        'userId': user.uid,
      });

      if (result.data != null && result.data['text'] != null) {
        return result.data['text'] as String;
      } else {
        throw Exception("Received invalid response from Cloud Function.");
      }
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      // Melempar kembali error untuk ditangani oleh UI
      throw Exception('Error from AI service: ${e.message}');
    } catch (e) {
      print("Unexpected error sending message: $e");
      rethrow;
    }
  }
}