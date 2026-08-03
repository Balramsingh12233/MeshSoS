import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// ChatInputField — bottom message composer bar.
///
/// Layout:  [🛡 SOS] [Type a message.....................] [➤]
///
/// The SOS shield button sits on the LEFT of the text field,
/// matching the WhatsApp attachment-button pattern. It is always
/// visible and never overlaps the send button on the right.
class ChatInputField extends StatefulWidget {
  final Function(String text) onSendMessage;
  final VoidCallback? onSosTap;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    this.onSosTap,
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Left: SOS Shield button ────────────────────────────────────
            if (widget.onSosTap != null)
              GestureDetector(
                onTap: widget.onSosTap,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sosAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sosAccent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.sosAccent,
                    size: 20,
                  ),
                ),
              ),

            // ── Centre: Pill text field ────────────────────────────────────
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ── Right: Send button ─────────────────────────────────────────
            GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _hasText
                    ? AppColors.transportMesh
                    : AppColors.surfaceVariant,
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: _hasText
                      ? AppColors.background
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
