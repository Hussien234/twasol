import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  audio, // Add this line for the 'audio' type
}

class Message {
  String senderId;
  String senderEmail;
  String reciveID;
  Timestamp timestamp;
  String message;
  MessageType messageType;
  bool seen;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.reciveID,
    required this.timestamp,
    required this.message,
    required this.messageType,
    required this.seen,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'reciveID': reciveID,
      'timestamp': timestamp,
      'message': message,
      'messageType': messageType.index,
      'seen': seen,

    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      reciveID: map['reciveID'],
      timestamp: map['timestamp'],
      message: map['message'],
      messageType: MessageType.values[map['messageType']],
      seen: map['seen'],
    );
  }
}
