import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, voice }

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final String? fileUrl;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
    this.fileUrl,
  });

  @override
  List<Object?> get props => [id];
}
