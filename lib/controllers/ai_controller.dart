import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiController extends GetxController {
  final AiService _aiService = Get.find<AiService>();
  late TextEditingController chatTextController;
  
  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    chatTextController = TextEditingController();
  }

  @override
  void onClose() {
    chatTextController.dispose();
    super.onClose();
  }

  void setPageContext(String text) {
    _aiService.updateContext(text);
  }

  Future<void> askQuestion() async {
    String question = chatTextController.text;
    if (question.trim().isEmpty) return;
    
    chatTextController.clear();
    messages.add({'role': 'user', 'content': question});
    isLoading.value = true;
    
    String response = await _aiService.askQuestion(question);
    
    messages.add({'role': 'ai', 'content': response});
    isLoading.value = false;
  }
}
