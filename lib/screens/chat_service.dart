import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twasol/screens/message.dart';
import 'package:twasol/screens/chat.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String receiverId, String message, MessageType messageType) async {
    // ... existing code ...
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      reciveID: receiverId,
      timestamp: timestamp,
      message: message,
      messageType: messageType,
      seen: false, // Set initial seen status to false
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
  }
  Future<File> getLocalImageFile(String imagePath) async {
    final File imageFile = File(imagePath);
    return imageFile;
  }
  Future<String> _uploadImageToStorage(String imagePath) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference storageReference =
    storage.ref().child('images/chat/${DateTime.now()}.png');
    UploadTask uploadTask = storageReference.putFile(File(imagePath));

    TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
  Future<void> updateMessageSeenStatus(DocumentReference messageRef, String currentUserId) async {
    await messageRef.update({
      'seen': true,
    });
  }


  Future<void> sendImageMessage(String receiverId, String imagePath, MessageType messageType) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    String imageUrl = await _uploadImageToStorage(imagePath);

    Message newImageMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      reciveID: receiverId,
      timestamp: timestamp,
      message: imageUrl,
      messageType: messageType,
      seen: false,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("messages")
        .add(newImageMessage.toMap());
  }


  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  Future<void> sendAudioMessage(String receiverId, String audioPath, MessageType messageType) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    String audioUrl = await _uploadAudioToStorage(audioPath);

    Message newAudioMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      reciveID: receiverId,
      timestamp: timestamp,
      message: audioUrl,
      messageType: messageType,
      seen: false,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection("messages")
        .add(newAudioMessage.toMap());
  }

  Future<String> _uploadAudioToStorage(String audioPath) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference storageReference =
    storage.ref().child('audio_messages/${DateTime.now()}.aac');
    UploadTask uploadTask = storageReference.putFile(File(audioPath));

    TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
}
