import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/session/session_state.dart';
import '../providers/session_provider.dart';
import '../services/webrtc_service.dart';

/// Student side of a live class. Dark "call surface" (same tokens as the
/// web session page): status header, teacher tile, chat, control bar.
class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({
    super.key,
    required this.sessionId,
    this.title,
  });

  final String sessionId;
  final String? title;

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  late final SessionParams _params;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  String? _lastShownError;

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
    _scrollController.dispose();
    // No ref.read here: the element is already deactivated in dispose()
    // ("Looking up a deactivated widget's ancestor is unsafe"). The
    // autoDispose sessionProvider's onDispose -> SessionNotifier.dispose()
    // already emits leave_session and tears the socket down.
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = ref.watch(sessionProvider(_params));
    final notifier = ref.read(sessionProvider(_params).notifier);

    // Surface session errors (rate limit, not-live, etc.) once each.
    ref.listen<SessionState>(sessionProvider(_params), (prev, next) {
      final err = next.errorMessage;
      if (err != null && err != _lastShownError) {
        _lastShownError = err;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.darkCard),
        );
        notifier.clearError();
      }
      if (next.chatMessages.length != (prev?.chatMessages.length ?? 0)) {
        _scrollToBottom();
      }
      if (next.sessionEnded && !(prev?.sessionEnded ?? false)) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && context.canPop()) context.pop();
        });
      }
    });

    final teacher =
        session.participants.where((p) => p.role == 'teacher').firstOrNull;
    final title = widget.title ?? 'Live class';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showLeaveConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                title: title,
                status: session.connectionStatus,
                teacherName: teacher?.name,
                participantCount: session.participants.length,
                isRecording: session.isRecording,
                mutedByTeacher: session.mutedByTeacher,
              ),
              if (session.connectionStatus == SessionConnectionStatus.error &&
                  session.sessionEnded == false)
                _ErrorStage(
                  message: session.errorMessage ?? 'Could not join the class.',
                  onBack: () => context.pop(),
                )
              else if (session.sessionEnded)
                const _EndedStage()
              else
                _TeacherStage(
                  teacherName: teacher?.name,
                  mode: session.currentMode,
                  connected: session.connectionStatus ==
                      SessionConnectionStatus.connected,
                  bandwidthKbps: session.estimatedBandwidthKbps,
                ),
              if (session.activePoll != null)
                _PollBanner(
                  poll: session.activePoll!,
                  onVote: (option) =>
                      notifier.votePoll(session.activePoll!.id, option),
                ),
              Expanded(
                child: _ChatPanel(
                  messages: session.chatMessages,
                  participantCount: session.participants.length,
                  selfId: _params.studentId,
                  controller: _chatController,
                  scrollController: _scrollController,
                  enabled: session.connectionStatus ==
                      SessionConnectionStatus.connected,
                  onSend: () {
                    final text = _chatController.text.trim();
                    if (text.isEmpty) return;
                    notifier.sendMessage(text);
                    _chatController.clear();
                    _scrollToBottom();
                  },
                ),
              ),
              _ControlBar(
                handRaised: session.handRaised,
                connected: session.connectionStatus ==
                    SessionConnectionStatus.connected,
                onRaiseHand: () {
                  notifier.raiseHand();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hand raised — the teacher can see it.'),
                      backgroundColor: AppColors.darkCard,
                    ),
                  );
                },
                onLeave: _showLeaveConfirmation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the class?'),
        content: const Text('You can rejoin from your dashboard while it is live.'),
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.status,
    required this.teacherName,
    required this.participantCount,
    required this.isRecording,
    required this.mutedByTeacher,
  });

  final String title;
  final SessionConnectionStatus status;
  final String? teacherName;
  final int participantCount;
  final bool isRecording;
  final bool mutedByTeacher;

  @override
  Widget build(BuildContext context) {
    final (dotColor, label) = switch (status) {
      SessionConnectionStatus.connected => (AppColors.online, 'Connected'),
      SessionConnectionStatus.connecting => (AppColors.accent, 'Joining…'),
      SessionConnectionStatus.reconnecting =>
        (AppColors.accent, 'Reconnecting…'),
      SessionConnectionStatus.disconnected => (AppColors.ended, 'Disconnected'),
      SessionConnectionStatus.error => (AppColors.live, 'Error'),
    };
    final meta = [
      label,
      if (teacherName != null) teacherName!,
      '$participantCount in room',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge(
                      color: AppColors.darkTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                      color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          if (mutedByTeacher) ...[
            const SizedBox(width: 8),
            const _Pill(
                text: 'MUTED',
                color: AppColors.darkWarnText,
                background: Color(0x29F59E0B)),
          ],
          if (isRecording) ...[
            const SizedBox(width: 8),
            const _Pill(
                text: 'REC',
                color: AppColors.darkLiveText,
                background: Color(0x29E11D48),
                dot: true),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.background,
    this.dot = false,
  });

  final String text;
  final Color color;
  final Color background;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AppTextStyles.labelSmall(color: color)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stage (teacher tile / states)
// ---------------------------------------------------------------------------
class _TeacherStage extends StatelessWidget {
  const _TeacherStage({
    required this.teacherName,
    required this.mode,
    required this.connected,
    required this.bandwidthKbps,
  });

  final String? teacherName;
  final SessionMode mode;
  final bool connected;
  final int bandwidthKbps;

  @override
  Widget build(BuildContext context) {
    final name = teacherName ?? 'Teacher';
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    final (icon, text, color) = switch ((connected, mode, teacherName)) {
      (false, _, _) => (Icons.hourglass_top_rounded, 'Joining the room…', AppColors.darkTextSecondary),
      (true, _, null) => (Icons.hourglass_top_rounded, 'Waiting for the teacher…', AppColors.darkTextSecondary),
      (true, SessionMode.text, _) => (Icons.chat_bubble_outline_rounded, 'Text mode — low bandwidth', AppColors.darkWarnText),
      (true, _, _) => (Icons.volume_up_rounded, 'Listening · audio', AppColors.darkOnlineText),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x2E6366F1), width: 8),
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: AppTextStyles.displayMedium(color: Colors.white)
                  .copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: AppTextStyles.titleLarge(color: AppColors.darkTextPrimary)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(text, style: AppTextStyles.bodySmall(color: color)),
              if (bandwidthKbps > 0) ...[
                Text(' · ',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.darkTextSecondary)),
                Text('$bandwidthKbps kbps',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.darkTextSecondary)),
              ],
            ],
          ),
          if (!WebRtcService.hasTurn) ...[
            const SizedBox(height: 6),
            Text('STUN only — audio may fail on mobile data',
                style: AppTextStyles.labelSmall(
                    color: AppColors.darkTextSecondary)),
          ],
        ],
      ),
    );
  }
}

class _ErrorStage extends StatelessWidget {
  const _ErrorStage({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Could not join',
              style: AppTextStyles.headlineSmall(color: AppColors.darkTextPrimary)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(onPressed: onBack, child: const Text('Back to dashboard')),
          ),
        ],
      ),
    );
  }
}

class _EndedStage extends StatelessWidget {
  const _EndedStage();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Class has ended',
              style: AppTextStyles.headlineSmall(color: AppColors.darkTextPrimary)),
          const SizedBox(height: 6),
          Text('Taking you back to your dashboard…',
              style: AppTextStyles.bodyMedium(color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Poll banner (poll_created / poll_response)
// ---------------------------------------------------------------------------
class _PollBanner extends StatelessWidget {
  const _PollBanner({required this.poll, required this.onVote});
  final ActivePoll poll;
  final void Function(String option) onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POLL', style: AppTextStyles.eyebrow(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 4),
          Text(poll.question,
              style: AppTextStyles.titleMedium(color: AppColors.darkTextPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in poll.options)
                ChoiceChip(
                  label: Text(option),
                  selected: poll.selectedOption == option,
                  onSelected: poll.selectedOption == null
                      ? (_) => onVote(option)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------
class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.participantCount,
    required this.selfId,
    required this.controller,
    required this.scrollController,
    required this.enabled,
    required this.onSend,
  });

  final List<ChatMessage> messages;
  final int participantCount;
  final String selfId;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Row(
              children: [
                Text('CHAT',
                    style: AppTextStyles.eyebrow(color: AppColors.darkTextSecondary)),
                const Spacer(),
                Text('$participantCount participants',
                    style: AppTextStyles.bodySmall(color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('Messages everyone in the room can see.',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.darkTextSecondary)),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ChatBubble(
                      message: messages[i],
                      isMine: messages[i].senderId == selfId,
                    ),
                  ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      maxLength: 2000,
                      style: AppTextStyles.bodyMedium(color: AppColors.darkTextPrimary),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: enabled ? 'Message…' : 'Connecting…',
                        hintStyle: AppTextStyles.bodyMedium(
                            color: AppColors.darkTextSecondary),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primaryLight),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: enabled ? AppColors.primary : AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: enabled ? onSend : null,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});
  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.timestamp.toLocal()).format(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              '${isMine ? 'You' : message.senderName} · $time',
              style: AppTextStyles.labelSmall(color: AppColors.darkTextSecondary)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.darkBorder,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMine ? 12 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 12),
                ),
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium(color: AppColors.darkTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control bar
// ---------------------------------------------------------------------------
class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.handRaised,
    required this.connected,
    required this.onRaiseHand,
    required this.onLeave,
  });

  final bool handRaised;
  final bool connected;
  final VoidCallback onRaiseHand;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      color: AppColors.darkCard,
      child: Row(
        children: [
          Expanded(
            child: _ControlButton(
              icon: Icons.front_hand_rounded,
              label: handRaised ? 'Hand raised' : 'Raise hand',
              onTap: connected && !handRaised ? onRaiseHand : null,
              background: handRaised ? const Color(0x29F59E0B) : AppColors.darkBorder,
              foreground: handRaised ? AppColors.darkWarnText : AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ControlButton(
              icon: Icons.logout_rounded,
              label: 'Leave',
              onTap: onLeave,
              background: AppColors.live,
              foreground: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: onTap == null ? background.withValues(alpha: 0.5) : background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.button(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
