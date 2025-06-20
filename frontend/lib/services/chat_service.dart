import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  // Get current user email
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // Get all users (for chat list)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Get chat messages between two users
  Stream<List<ChatMessage>> getChatMessages(String otherUserEmail) {
    final currentEmail = currentUserEmail;
    
    // Create a unique chat ID for the two users
    final chatId = getChatId(currentEmail, otherUserEmail);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()))
              .toList();
        });
  }

  // Send a message
  Future<void> sendMessage(String receiverEmail, String messageText) async {
    final currentEmail = currentUserEmail;
    final chatId = getChatId(currentEmail, receiverEmail);
    
    // Create a new message with isRead explicitly set to false
    final message = ChatMessage(
      id: _uuid.v4(),
      senderEmail: currentEmail,
      receiverEmail: receiverEmail,
      message: messageText,
      timestamp: DateTime.now(),
      isRead: false, // Explicitly set isRead to false
    );
    
    // Save the message to Firestore
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
        
    // Also update the chat document to track the last message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .set({
          'lastMessage': messageText,
          'lastMessageTime': message.timestamp,
          'lastMessageSender': currentEmail,
          'lastMessageRead': false,
        }, SetOptions(merge: true));
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderEmail) async {
    final currentEmail = currentUserEmail;
    final chatId = getChatId(currentEmail, senderEmail);
    
    // Get unread messages
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: currentEmail)
        .where('isRead', isEqualTo: false)
        .get();
    
    // Update each unread message
    final batch = _firestore.batch();
    
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    // Also update the chat document to mark the last message as read
    batch.update(
      _firestore.collection('chats').doc(chatId),
      {'lastMessageRead': true}
    );
    
    await batch.commit();
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount() {
    final currentEmail = currentUserEmail;
    
    return _firestore
        .collectionGroup('messages')
        .where('receiverEmail', isEqualTo: currentEmail)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get unread message count for a specific chat
  Stream<int> getUnreadMessageCountForChat(String otherUserEmail) {
    final currentEmail = currentUserEmail;
    final chatId = getChatId(currentEmail, otherUserEmail);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: currentEmail)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get recent chats (users with whom the current user has chatted)
  Stream<List<String>> getRecentChats() {
    final currentEmail = currentUserEmail;
    
    return _firestore
        .collection('chats')
        .snapshots()
        .map((snapshot) {
          final List<String> recentChats = [];
          
          for (var doc in snapshot.docs) {
            final chatId = doc.id;
            final participants = chatId.split('_');
            
            if (participants.contains(currentEmail)) {
              final otherUser = participants.firstWhere(
                (email) => email != currentEmail,
                orElse: () => '',
              );
              
              if (otherUser.isNotEmpty) {
                recentChats.add(otherUser);
              }
            }
          }
          
          return recentChats;
        });
  }

  // Helper method to create a consistent chat ID for two users
  String getChatId(String email1, String email2) {
    // Sort emails to ensure consistent chat ID regardless of who initiates
    final sortedEmails = [email1, email2]..sort();
    return '${sortedEmails[0]}_${sortedEmails[1]}';
  }
} 