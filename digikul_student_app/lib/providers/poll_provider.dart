import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll.dart';
import '../services/api_service_new.dart';
import 'auth_provider.dart';

// Polls state
class PollsState {
  final List<Poll> studentPolls;
  final Map<String, List<Poll>> lecturePolls;
  final Map<String, PollResults> pollResults;
  final Map<String, String> userVotes; // pollId -> selectedOption
  final bool isLoading;
  final String? error;

  const PollsState({
    this.studentPolls = const [],
    this.lecturePolls = const {},
    this.pollResults = const {},
    this.userVotes = const {},
    this.isLoading = false,
    this.error,
  });

  PollsState copyWith({
    List<Poll>? studentPolls,
    Map<String, List<Poll>>? lecturePolls,
    Map<String, PollResults>? pollResults,
    Map<String, String>? userVotes,
    bool? isLoading,
    String? error,
  }) {
    return PollsState(
      studentPolls: studentPolls ?? this.studentPolls,
      lecturePolls: lecturePolls ?? this.lecturePolls,
      pollResults: pollResults ?? this.pollResults,
      userVotes: userVotes ?? this.userVotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Poll> getPolls(String lectureId) {
    return lecturePolls[lectureId] ?? [];
  }

  PollResults? getResults(String pollId) {
    return pollResults[pollId];
  }

  String? getUserVote(String pollId) {
    return userVotes[pollId];
  }

  bool hasUserVoted(String pollId) {
    return userVotes.containsKey(pollId);
  }
}

// Polls notifier
class PollsNotifier extends StateNotifier<PollsState> {
  PollsNotifier(this._apiService) : super(const PollsState());

  final ApiService _apiService;

  Future<void> loadStudentPolls() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final polls = await _apiService.getStudentPolls();
      state = state.copyWith(
        studentPolls: polls,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadLecturePolls(String lectureId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final polls = await _apiService.getLecturePolls(lectureId);
      final updatedPolls = Map<String, List<Poll>>.from(state.lecturePolls);
      updatedPolls[lectureId] = polls;
      
      state = state.copyWith(
        lecturePolls: updatedPolls,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> voteOnPoll(String pollId, String response) async {
    try {
      await _apiService.voteOnPoll(pollId, response);
      
      // Update local state to reflect the vote
      final updatedVotes = Map<String, String>.from(state.userVotes);
      updatedVotes[pollId] = response;
      
      state = state.copyWith(userVotes: updatedVotes);
      
      // Load updated results
      await loadPollResults(pollId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> loadPollResults(String pollId) async {
    try {
      final results = await _apiService.getPollResults(pollId);
      final updatedResults = Map<String, PollResults>.from(state.pollResults);
      updatedResults[pollId] = results;
      
      state = state.copyWith(pollResults: updatedResults);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Add a poll to the state (useful for real-time updates)
  void addPoll(Poll poll) {
    if (poll.lectureId != null) {
      final lectureId = poll.lectureId!;
      final updatedPolls = Map<String, List<Poll>>.from(state.lecturePolls);
      final currentPolls = updatedPolls[lectureId] ?? [];
      
      // Check if poll already exists
      if (!currentPolls.any((p) => p.id == poll.id)) {
        updatedPolls[lectureId] = [...currentPolls, poll];
        state = state.copyWith(lecturePolls: updatedPolls);
      }
    }
    
    // Also add to student polls if not already present
    if (!state.studentPolls.any((p) => p.id == poll.id)) {
      state = state.copyWith(
        studentPolls: [...state.studentPolls, poll],
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final pollsProvider = StateNotifierProvider<PollsNotifier, PollsState>((ref) {
  return PollsNotifier(ref.read(apiServiceProvider));
});

// Helper providers
final studentPollsProvider = Provider<List<Poll>>((ref) {
  return ref.watch(pollsProvider).studentPolls;
});

final lecturePollsProvider = Provider.family<List<Poll>, String>((ref, lectureId) {
  return ref.watch(pollsProvider).getPolls(lectureId);
});

final pollResultsProvider = Provider.family<PollResults?, String>((ref, pollId) {
  return ref.watch(pollsProvider).getResults(pollId);
});

final userVoteProvider = Provider.family<String?, String>((ref, pollId) {
  return ref.watch(pollsProvider).getUserVote(pollId);
});

final hasUserVotedProvider = Provider.family<bool, String>((ref, pollId) {
  return ref.watch(pollsProvider).hasUserVoted(pollId);
});
