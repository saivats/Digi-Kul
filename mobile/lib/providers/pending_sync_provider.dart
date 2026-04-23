import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/quiz_repository.dart';

part 'pending_sync_provider.g.dart';

@riverpod
Future<int> pendingSyncCount(PendingSyncCountRef ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.pendingSubmissionCount();
}
