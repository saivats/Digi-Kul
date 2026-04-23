import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/session/session_state.dart';
import '../providers/session_provider.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  late final SessionParams _params;
  final _chatController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initParams();
  }

  Future<void> _initParams() async {
    final token = await SecureStorageService.getAuthToken();
    final studentId = PreferencesService.studentId ?? '';
    final studentName = PreferencesService.studentName ?? 'Student';

    _params = SessionParams(
      sessionId: widget.sessionId,
      authToken: token ?? '',
      studentId: studentId,
      studentName: studentName,
    );

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    if (_isInitialized) {
      ref.read(sessionProvider(_params).notifier).leaveSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = ref.watch(sessionProvider(_params));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showLeaveConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Live Session', style: AppTextStyles.titleLarge()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _showLeaveConfirmation,
          ),
          actions: [
            _ConnectionBadge(status: session.connectionStatus),
            const SizedBox(width: 8),
            _ModeBadge(mode: session.currentMode),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            if (session.activePoll != null)
              _PollBanner(
                poll: session.activePoll!,
                onVote: (option) {
                  ref
                      .read(sessionProvider(_params).notifier)
                      .votePoll(session.activePoll!.id, option);
                },
              ),
            _ParticipantBar(participants: session.participants),
            Expanded(
              child: _ChatArea(messages: session.chatMessages),
            ),
            _ChatInput(
              controller: _chatController,
              onSend: () {
                final text = _chatController.text.trim();
                if (text.isEmpty) return;
                ref.read(sessionProvider(_params).notifier).sendMessage(text);
                _chatController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Session?'),
        content: const Text('You will be disconnected from the live session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});

  final SessionConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SessionConnectionStatus.connected => (AppColors.success, Icons.wifi),
      SessionConnectionStatus.connecting => (
          AppColors.warning,
          Icons.wifi_find
        ),
      SessionConnectionStatus.reconnecting => (
          AppColors.warning,
          Icons.wifi_find
        ),
      SessionConnectionStatus.disconnected => (AppColors.error, Icons.wifi_off),
      SessionConnectionStatus.error => (AppColors.error, Icons.error_outline),
    };

    return Icon(icon, color: color, size: 20);
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final SessionMode mode;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (mode) {
      SessionMode.video => ('Video', Icons.videocam),
      SessionMode.audio => ('Audio', Icons.headphones),
      SessionMode.text => ('Text', Icons.chat),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ParticipantBar extends StatelessWidget {
  const _ParticipantBar({required this.participants});

  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '${participants.length} participant${participants.length == 1 ? '' : 's'}',
            style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PollBanner extends StatelessWidget {
  const _PollBanner({
    required this.poll,
    required this.onVote,
  });

  final ActivePoll poll;
  final void Function(String option) onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.question, style: AppTextStyles.titleMedium()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: poll.options.map((option) {
              final isSelected = poll.selectedOption == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected:
                    poll.selectedOption == null ? (_) => onVote(option) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  const _ChatArea({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _ChatBubble(message: message);
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isTeacher = message.senderRole == 'teacher';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isTeacher
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.textSecondary.withValues(alpha: 0.15),
            child: Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.labelSmall(
                color: isTeacher ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: AppTextStyles.labelSmall(
                    color:
                        isTeacher ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message.content, style: AppTextStyles.bodyMedium()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
