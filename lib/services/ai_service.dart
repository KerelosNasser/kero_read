import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AiService extends GetxService {
  late String _apiKey;
  late GenerativeModel _model;
  late ChatSession _chat;
  String _currentModel = 'gemini-3.5-flash';

  String _currentPageContext = '';

  static const List<String> _fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-3-flash',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemma-4-26b',
    'gemma-4-31b',
  ];

  Future<AiService> init() async {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) throw Exception("Gemini API key missing");

    _initModel(_currentModel);
    return this;
  }

  void _initModel(String modelName) {
    _currentModel = modelName;
    if (kDebugMode) debugPrint("Initializing Gemini model: $_currentModel");
    _model = GenerativeModel(model: _currentModel, apiKey: _apiKey);
    _chat = _model.startChat();
  }

  void resetChat() {
    _chat = _model.startChat();
    _currentPageContext = '';
  }

  void updateContext(String text) {
    _currentPageContext = text;
  }

  Content _buildPromptContent(String question, Uint8List? imageBytes, {String? customContext}) {
    const String systemPrompt =
        "You are an expert tutor. Answer the question based on the PDF text/image.\n"
        "Guidelines:\n"
        "1. NO filler, NO intro/outro (e.g. 'Sure!', 'Here is the explanation', 'Let me know...'). Start directly with the answer/explanation.\n"
        "2. Minimize tokens: Be extremely brief, concise, and structured. Use short bullet points.\n"
        "3. Render math equations using standard LaTeX (\$...\$ for inline, \$\$...\$\$ for block).\n"
        "4. Render tables using standard markdown.\n"
        "5. Break down complex formulas/concepts step-by-step simply.";

    final promptText =
        "$systemPrompt\n\n"
        "Text context: ${customContext ?? _currentPageContext}\n\n"
        "Question: $question";

    return Content.multi([
      TextPart(promptText),
      if (imageBytes != null) DataPart('image/png', imageBytes),
    ]);
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes, String? customContext}) async {
    try {
      final content = _buildPromptContent(question, imageBytes, customContext: customContext);

      // Try sending with current model first
      try {
        var response = await _chat.sendMessage(content);
        return response.text ?? 'No response';
      } catch (e) {
        if (kDebugMode) debugPrint("Error sending with $_currentModel: $e");

        // If current model fails, iterate through fallback list to find a working model
        for (String modelName in _fallbackModels) {
          if (modelName == _currentModel) continue;

          try {
            if (kDebugMode) debugPrint("Falling back to model: $modelName");
            _initModel(modelName);
            var response = await _chat.sendMessage(content);
            return response.text ?? 'No response';
          } catch (fallbackErr) {
            if (kDebugMode) debugPrint("Fallback model $modelName failed: $fallbackErr");
          }
        }

        // If all fail, rethrow the original error
        rethrow;
      }
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  Stream<String> askQuestionStream(String question, {Uint8List? imageBytes, String? customContext}) async* {
    try {
      final content = _buildPromptContent(question, imageBytes, customContext: customContext);

      // Try sending stream with current model first
      try {
        final responseStream = _chat.sendMessageStream(content);
        await for (final response in responseStream) {
          if (response.text != null) {
            yield response.text!;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Error sending stream with $_currentModel: $e");
        
        bool success = false;
        // If current model fails, iterate through fallback list to find a working model
        for (String modelName in _fallbackModels) {
          if (modelName == _currentModel) continue;
          
          try {
            if (kDebugMode) debugPrint("Falling back to model for streaming: $modelName");
            _initModel(modelName);
            final responseStream = _chat.sendMessageStream(content);
            await for (final response in responseStream) {
              if (response.text != null) {
                yield response.text!;
              }
            }
            success = true;
            break;
          } catch (fallbackErr) {
            if (kDebugMode) debugPrint("Fallback model $modelName failed during stream: $fallbackErr");
          }
        }
        
        if (!success) {
          rethrow;
        }
      }
    } catch (e) {
      yield 'Error generating response: $e';
    }
  }
}
