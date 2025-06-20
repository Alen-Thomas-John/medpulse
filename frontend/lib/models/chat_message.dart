class ChatMessage {
  final String id;
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  // Convert a ChatMessage object to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  // Create a ChatMessage from a Firestore document
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverEmail: map['receiverEmail'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
} 