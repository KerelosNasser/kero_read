import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../controllers/ai_controller.dart';
import 'glassy_container.dart';

class AiChatBottomSheet extends StatefulWidget {
  final String? initialQuestion;

  const AiChatBottomSheet({super.key, this.initialQuestion});

  static void show(BuildContext context, {String? initialQuestion}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      showDragHandle: false, // we render our own styled handle
      builder: (context) => AiChatBottomSheet(initialQuestion: initialQuestion),
    );
  }

  @override
  State<AiChatBottomSheet> createState() => _AiChatBottomSheetState();
}

class _AiChatBottomSheetState extends State<AiChatBottomSheet> {
  late final AiController aiController;

  @override
  void initState() {
    super.initState();
    aiController = Get.find<AiController>();

    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 350), () {
        aiController.chatTextController.text = widget.initialQuestion!;
        aiController.askQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.55, 0.75, 0.92],
      builder: (context, scrollController) {
        return GlassyContainer(
          width: MediaQuery.of(context).size.width,
          height: screenHeight * 0.92, // max possible — DraggableScrollableSheet clips it
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          blurX: 15.0,
          blurY: 15.0,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset + 16,
              left: 16,
              right: 16,
              top: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Gemini AI Assistant",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),

                // Chat Messages Area
                Expanded(
                  child: Obx(() {
                    if (aiController.messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: aiController.messages.length,
                      itemBuilder: (context, index) {
                        final msg = aiController.messages[index];
                        final bool isUser = msg['role'] == 'user';
                        return _buildMessageRow(msg, isUser);
                      },
                    );
                  }),
                ),

                // Loading indicator — scoped Obx
                Obx(() => aiController.isLoading.value
                    ? _buildLoadingIndicator()
                    : const SizedBox.shrink()),

                const SizedBox(height: 8),

                // Input box — only send button needs Obx
                _buildInputBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              "Ask anything about this page",
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Supports equations, tables, and general concepts.",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: aiController.suggestionChips.map((chipText) {
                return ActionChip(
                  label: Text(
                    chipText,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                  onPressed: () => aiController.askPresetQuestion(chipText),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(Map<String, String> msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAiAvatar(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    (isUser ? 0.75 : 0.85),
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: isUser
                  ? Text(
                      msg['content'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : GptMarkdown(
                      msg['content'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
            ),
          ),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 0.5),
      ),
      child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          Text(
            "Gemini is thinking...",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: aiController.chatTextController,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: "Ask about this page...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Only this button reacts to isLoading — narrow Obx scope
          Obx(() => Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: aiController.isLoading.value
                      ? null
                      : () => aiController.askQuestion(),
                ),
              )),
        ],
      ),
    );
  }
}
