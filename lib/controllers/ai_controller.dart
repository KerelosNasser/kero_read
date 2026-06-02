import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'reader_controller.dart';

class AiController extends GetxController {
  final AiService _aiService = Get.find<AiService>();
  late TextEditingController chatTextController;
  late ScrollController scrollController;
  
  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;

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
    _aiService.updateContext(text);
  }

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

  Future<void> askPresetQuestion(String question) async {
    chatTextController.text = question;
    await askQuestion();
  }

  Future<void> askQuestion() async {
    if (isLoading.value) return;
    
    String question = chatTextController.text;
    if (question.trim().isEmpty) return;
    
    chatTextController.clear();
    messages.add({'role': 'user', 'content': question});
    scrollToBottom();
    isLoading.value = true;
    
    try {
      Uint8List? imageBytes;
      try {
        final readerController = Get.find<ReaderController>();
        imageBytes = await readerController.renderCurrentPageAsImage();
      } catch (e) {
        debugPrint("Could not render page image: $e");
      }
      
      String response = await _aiService.askQuestion(question, imageBytes: imageBytes);
      messages.add({'role': 'ai', 'content': response});
      scrollToBottom();
    } finally {
      isLoading.value = false;
      scrollToBottom();
    }
  }
}
