import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService extends GetxService {
  late GenerativeModel _model;
  late ChatSession _chat;
  
  String _currentPageContext = '';

  Future<AiService> init() async {
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception("Gemini API key missing");

    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _chat = _model.startChat();
    return this;
  }

  void updateContext(String text) {
    _currentPageContext = text;
  }

  Future<String> askQuestion(String question) async {
    try {
      String prompt = "Context from current PDF page:\n$_currentPageContext\n\nQuestion: $question";
      var response = await _chat.sendMessage(Content.text(prompt));
      return response.text ?? 'No response';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }
}
