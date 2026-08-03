import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// ChatInputField is the bottom text composer bar widget.
/// 
/// Google Product Design Highlights:
/// - Rounded pill-shaped TextField matching Material 3 guidelines.
/// - Dark surface styling (`#1E1E1E`) with subtle border highlight on focus.
/// - Clean send icon button with active press state.
class ChatInputField extends StatefulWidget {
  final Function(String text) onSendMessage;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.background,
      child: SafeArea(
        child: Row(
          children: [
            // Expanded text input box
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24), // Pill shape
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Circular send button
            GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _hasText ? AppColors.textPrimary : AppColors.surfaceVariant,
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: _hasText ? AppColors.background : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
