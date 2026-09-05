import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'reader_controller.dart';

class ChatMessage {
  final String role;
  final RxString content;

  ChatMessage({required this.role, required String initialContent})
    : content = initialContent.obs;
}

class AiController extends GetxController {
  final AiService _aiService = Get.find<AiService>();
  late TextEditingController chatTextController;
  late ScrollController scrollController;

  var messages = <ChatMessage>[].obs;
  var isLoading = false.obs;

  bool _needsScroll = false;
  bool _scrollScheduled = false;

  final List<String> suggestionChips = [
    "Explain this page",
    "List formulas",
    "Break down equations",
    "Summarize takeaways",
  ];

  @override
  void onInit() {
    super.onInit();
    chatTextController = TextEditingController();
    scrollController = ScrollController();
    _aiService.resetChat();
  }

  @override
  void onClose() {
    chatTextController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void setPageContext(String text) {
    _aiService.setPageContext(text);
  }

  /// True when page context is already loaded (skip redundant re-extraction).
  bool get hasPageContext => _aiService.hasPageContext;

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Throttled scroll during streaming — at most one frame callback queued at a time.
  void _scheduleScrollToBottom() {
    _needsScroll = true;
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_needsScroll && scrollController.hasClients) {
        _needsScroll = false;
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> askPresetQuestion(String question) async {
    chatTextController.text = question;
    await askQuestion();
  }

  Future<void> askQuestion() async {
    if (isLoading.value) return;

    final String question = chatTextController.text;
    if (question.trim().isEmpty) return;

    chatTextController.clear();
    messages.add(ChatMessage(role: 'user', initialContent: question));
    scrollToBottom();
    isLoading.value = true;

    try {
      final readerController = Get.find<ReaderController>();

      String? customContext;
      final qLower = question.toLowerCase();
      final wantsWholeDoc =
          qLower.contains('whole pdf') ||
          qLower.contains('entire pdf') ||
          qLower.contains('whole document') ||
          qLower.contains('entire document') ||
          qLower.contains('whole book') ||
          qLower.contains('entire book');

      if (wantsWholeDoc) {
        final wholeText = await readerController.extractPdfText(
          wholeDocument: true,
        );
        if (wholeText != null && wholeText.isNotEmpty) {
          customContext = wholeText;
        }
      }

      Uint8List? imageBytes;

      final hasTextContext = customContext != null
          ? customContext.isNotEmpty
          : _aiService.hasPageContext;

      if (!hasTextContext) {
        try {
          imageBytes = await readerController.renderCurrentPageAsImage();
        } catch (e) {
          if (kDebugMode) debugPrint('Could not render page image: $e');
        }
      }

      messages.add(ChatMessage(role: 'ai', initialContent: ''));
      final aiMessage = messages.last;
      scrollToBottom();

      String fullResponse = '';
      try {
        final stream = _aiService.askQuestionStream(
          question,
          imageBytes: imageBytes,
          customContext: customContext,
        );
        await for (final chunk in stream) {
          fullResponse += chunk;
          aiMessage.content.value = '$fullResponse ▊';
          _scheduleScrollToBottom();
        }
        aiMessage.content.value = fullResponse;
      } catch (e) {
        aiMessage.content.value = 'Error generating response: $e';
      }
      scrollToBottom();
    } finally {
      isLoading.value = false;
      scrollToBottom();
    }
  }
}
