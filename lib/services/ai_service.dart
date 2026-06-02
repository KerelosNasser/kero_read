import 'dart:typed_data';
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

  void resetChat() {
    _chat = _model.startChat();
    _currentPageContext = '';
  }

  void updateContext(String text) {
    _currentPageContext = text;
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes}) async {
    try {
      final String systemPrompt =
          "You are an expert tutor. Answer the question based on the PDF text/image.\n"
          "Guidelines:\n"
          "1. NO filler, NO intro/outro (e.g. 'Sure!', 'Here is the explanation', 'Let me know...'). Start directly with the answer/explanation.\n"
          "2. Minimize tokens: Be extremely brief, concise, and structured. Use short bullet points.\n"
          "3. Render math equations using standard LaTeX (\$...\$ for inline, \$\$...\$\$ for block).\n"
          "4. Render tables using standard markdown.\n"
          "5. Break down complex formulas/concepts step-by-step simply.";

      final promptText = "$systemPrompt\n\n"
          "Text context from page: $_currentPageContext\n\n"
          "Question: $question";

      final content = Content.multi([
        TextPart(promptText),
        if (imageBytes != null) DataPart('image/png', imageBytes),
      ]);

      var response = await _chat.sendMessage(content);
      return response.text ?? 'No response';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }
}
