class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final bool isTyping;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    this.isTyping = false,
    this.isError = false,
  });
}