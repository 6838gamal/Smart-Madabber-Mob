// lib/models/chat_message.dart
import 'dart:io';

enum MessageRole { user, assistant }

enum AttachmentType { none, audio, image, csv, xlsx, word, pdf, other }

class ChatAttachment {
  final String name;
  final String? path;
  final AttachmentType type;
  final int sizeBytes;

  const ChatAttachment({
    required this.name,
    required this.type,
    this.path,
    this.sizeBytes = 0,
  });
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final ChatAttachment? attachment;
  final bool isStreaming;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.attachment,
    this.isStreaming = false,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    bool? isError,
    ChatAttachment? attachment,
  }) =>
      ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        timestamp: timestamp,
        attachment: attachment ?? this.attachment,
        isStreaming: isStreaming ?? this.isStreaming,
        isError: isError ?? this.isError,
      );

  Map<String, dynamic> toApiJson() => {
        'role': role.name,
        'text': text,
        if (attachment != null) 'attachment': attachment!.name,
      };
}
