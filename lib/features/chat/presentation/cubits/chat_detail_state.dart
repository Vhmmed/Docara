part of 'chat_detail_cubit.dart';

sealed class ChatDetailState extends Equatable {
  const ChatDetailState();

  @override
  List<Object?> get props => [];
}

class ChatDetailInitial extends ChatDetailState {
  const ChatDetailInitial();
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

class ChatDetailLoaded extends ChatDetailState {
  final List<Map<String, dynamic>> messages;
  final String? snackbarMessage;
  final bool isLoadingMore;

  const ChatDetailLoaded(
    this.messages, {
    this.snackbarMessage,
    this.isLoadingMore = false,
  });

  ChatDetailLoaded copyWith({
    List<Map<String, dynamic>>? messages,
    String? snackbarMessage,
    bool? isLoadingMore,
    bool clearSnackbar = false,
  }) {
    return ChatDetailLoaded(
      messages ?? this.messages,
      snackbarMessage: clearSnackbar ? null : (snackbarMessage ?? this.snackbarMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [messages, snackbarMessage, isLoadingMore];
}

class ChatDetailError extends ChatDetailState {
  final String message;

  const ChatDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
