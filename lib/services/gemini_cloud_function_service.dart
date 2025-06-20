import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception("GEMINI_API_KEY not found in .env file");
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Anda bisa ganti model jika perlu
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String prompt) async {
    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      final text = response.text;

      if (text == null) {
        throw Exception("Received null response from Gemini.");
      }
      return text;
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }
}