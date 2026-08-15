import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/shared/widgets/no_connection_overlay.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/vote_poll.dart';
import 'home_providers.dart';

class PollCreationState {
  final String question;
  final List<String> options;
  final String timeframe;

  const PollCreationState({
    this.question = '',
    this.options = const ['', ''],
    this.timeframe = '3 days',
  });

  PollCreationState copyWith({
    String? question,
    List<String>? options,
    String? timeframe,
  }) {
    return PollCreationState(
      question: question ?? this.question,
      options: options ?? this.options,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  bool get isValid {
    if (question.trim().isEmpty) return false;
    final filledOptions = options.where((o) => o.trim().isNotEmpty).toList();
    return filledOptions.length >= 2;
  }

  Poll toPoll() {
    final filledOptions = options.where((o) => o.trim().isNotEmpty).toList();
    return Poll(
      question: question.trim(),
      options: filledOptions
          .asMap()
          .entries
          .map(
            (e) => PollOption(
              id: 'opt_${e.key}',
              text: e.value.trim(),
            ),
          )
          .toList(),
      duration: timeframe,
    );
  }
}

class PollCreationNotifier extends StateNotifier<PollCreationState> {
  PollCreationNotifier() : super(const PollCreationState());

  void setQuestion(String question) {
    state = state.copyWith(question: question);
  }

  void updateOption(int index, String value) {
    final newOptions = List<String>.from(state.options);
    newOptions[index] = value;
    state = state.copyWith(options: newOptions);
  }

  void addOption() {
    if (state.options.length < 6) {
      final newOptions = List<String>.from(state.options)..add('');
      state = state.copyWith(options: newOptions);
    }
  }

  void removeOption(int index) {
    if (state.options.length > 2) {
      final newOptions = List<String>.from(state.options)..removeAt(index);
      state = state.copyWith(options: newOptions);
    }
  }

  void setTimeframe(String timeframe) {
    state = state.copyWith(timeframe: timeframe);
  }

  void reset() {
    state = const PollCreationState();
  }
}

final pollCreationProvider =
    StateNotifierProvider<PollCreationNotifier, PollCreationState>(
  (ref) => PollCreationNotifier(),
);

class PollVoteNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<void> vote(String postId, String optionId) async {
    final isConnected = await checkInternet();
    if (!isConnected) {
      ref.read(showNoInternetOverlayProvider.notifier).state = true;
      return;
    }

    state = {...state, postId: optionId};

    final currentUserAsync = ref.read(currentUserProvider);
    final userId = currentUserAsync.requireValue.id;

    final result = await ref.read(votePollProvider)(
      VotePollParams(postId: postId, optionId: optionId, userId: userId),
    );

    result.fold(
      (failure) {
        state = Map.from(state)..remove(postId);
      },
      (_) {
        ref.invalidate(postsProvider);
      },
    );
  }
}

final pollVoteProvider =
    NotifierProvider<PollVoteNotifier, Map<String, String>>(
  PollVoteNotifier.new,
);
