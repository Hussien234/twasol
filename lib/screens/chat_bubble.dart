import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isImage;
  final Color backgroundColor;
  final bool seen;
  final Timestamp timestamp;
  final String Function(Timestamp) formatTimestamp;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isImage = false,
    required this.backgroundColor,
    required this.seen,
    required this.timestamp,
    required this.formatTimestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Column(
        children: [
          isImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: message.isNotEmpty
                ? Image.network(
              message,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            )
                : const SizedBox.shrink(),
          )
              : Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              seen
                  ? Icon(Icons.done_all, color: Colors.blue, size: 18)
                  : Icon(Icons.done, color: Colors.white, size: 18),
              Text(
                formatTimestamp(timestamp),
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


