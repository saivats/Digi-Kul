import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digikul_student_app/models/poll.dart';
import 'package:digikul_student_app/providers/poll_provider.dart';
import 'package:digikul_student_app/utils/app_colors.dart';
import 'package:digikul_student_app/utils/app_text_styles.dart';

class PollCard extends ConsumerStatefulWidget {

  const PollCard({
    super.key,
    required this.poll,
    this.onVote,
  });
  final Poll poll;
  final Function(String option)? onVote;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  String? _selectedOption;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    // Load poll results to check if user has already voted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pollsProvider.notifier).loadPollResults(widget.poll.id);
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOption == null || _isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      await widget.onVote?.call(_selectedOption!);
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUserVoted = ref.watch(hasUserVotedProvider(widget.poll.id));
    final userVote = ref.watch(userVoteProvider(widget.poll.id));
    final pollResults = ref.watch(pollResultsProvider(widget.poll.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.poll,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poll',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                      Text(
                        _formatDate(widget.poll.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (hasUserVoted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'VOTED',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Question
            Text(
              widget.poll.question,
              style: AppTextStyles.cardTitle,
            ),
            
            const SizedBox(height: 16),
            
            // Options
            if (hasUserVoted && pollResults != null)
              _buildResultsView(pollResults)
            else
              _buildVotingView(),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingView() {
    return Column(
      children: [
        ...widget.poll.options.map((option) {
          final isSelected = _selectedOption == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = option;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.outline,
                          width: 2,
                        ),
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.textPrimary,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 16),
        
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedOption != null && !_isVoting 
                ? _submitVote 
                : null,
            child: _isVoting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Submit Vote'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView(PollResults results) {
    return Column(
      children: [
        ...results.results.map((result) {
          final isUserChoice = ref.watch(userVoteProvider(widget.poll.id)) == result.option;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.option,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isUserChoice 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                          color: isUserChoice 
                              ? AppColors.primary 
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${result.votes} votes (${result.percentage.toStringAsFixed(1)}%)',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: isUserChoice 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                    if (isUserChoice) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: result.percentage / 100,
                  backgroundColor: AppColors.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUserChoice ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 8),
        
        Text(
          'Total votes: ${results.totalVotes}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
