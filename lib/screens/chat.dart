import 'package:flutter/material.dart';
import 'package:twasol/screens/chat_bubble.dart';
import 'package:twasol/screens/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:twasol/screens/message.dart';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:record/record.dart';
import 'package:twasol/screens/EthereumService.dart';
class chat extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const chat({
    Key? key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  }) : super(key: key);

  @override
  State<chat> createState() => _chatState();
}

class _chatState extends State<chat> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final EthereumService ethereumService = EthereumService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer audioPlayer = AudioPlayer();
  String? _imagePath;
  bool isRecording = false;
  String audioPath = '';
  bool isPlaying = false;
  late AudioRecorder audioRecorder;
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserID, _messageController.text, MessageType.text);
      await ethereumService.sendMessage(_messageController.text);
    } else if (_imagePath != null) {
      await _chatService.sendImageMessage(
          widget.receiverUserID, _imagePath!, MessageType.image);
      await ethereumService.sendMessage(_imagePath!);
    }

    _messageController.clear();
    _imagePath = null;
  }
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      print("App is in the foreground");

      // Example: Resume any background tasks or services
      resumeBackgroundTasks();

      // Example: Refresh data or update UI when the app is open
      refreshData();
    } else if (state == AppLifecycleState.paused) {
      // App is in the background
      print("App is in the background");

      // Example: Pause any ongoing tasks or services
      pauseBackgroundTasks();

      // Example: Save data or perform cleanup when the app is in the background
      saveData();
    }
  }

  void resumeBackgroundTasks() {
    // Example: Resume background tasks or services
  }

  void refreshData() {
    // Example: Refresh data or update UI when the app is open
  }

  void pauseBackgroundTasks() {
    // Example: Pause ongoing tasks or services
  }

  void saveData() {
    // Example: Save data or perform cleanup when the app is in the background
  }

  @override
  void initState() {
    super.initState();
    audioRecorder=AudioRecorder();
    ethereumService.connectToEthereum();
    _configureLocalNotifications();
    WidgetsBinding.instance!.addObserver(this);


    // Update to handle Firebase Cloud Messaging messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotification(message.data);
    });

    // Add the following lines to handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    fetchDataFromEthereum();
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print("Handling background message: ${message.messageId}");
    _handleNotification(message.data);
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    var status = await Permission.notification.request();

    if (status.isDenied) {
      print('Notification permission is denied');
    }
  }


  void _showNotification(String title, String body) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'chat_notification_channel_id',
      'Chat Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _playNotificationSound() async {
    try {
      await audioPlayer.play(
        AssetSource('assets/notification_sound.mp3'),
        volume: 20,
      );
    } catch (e) {
      print("Error playing notification sound: $e");
    }
  }
  void _handleNotification(Map<String, dynamic> message) {
    final String title = message['notification']['title'] ?? '';
    final String body = message['notification']['body'] ?? '';

    // Check if the message is sent by the current user
    if (message['data']['receiverUserID'] == widget.receiverUserID) {
      // Handle the notification (show notification, play sound, etc.)
      _showNotification(title, body);
      _playNotificationSound();
    }
  }



  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        widget.receiverUserID,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        print('StreamBuilder called');
        if (snapshot.hasError) {
          return Text('Error' + snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading..');
        }

        WidgetsBinding.instance!.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var document = snapshot.data!.docs[index];
            _handleNewMessage(document);
            return _buildMessageItem(document);
          },
        );
      },
    );
  }
  Widget _buildStatusIcon(Map<String, dynamic> data) {
    if (data['seen']) {
      return Icon(Icons.done_all, color: Colors.white, size: 18);
    } else {
      return Icon(Icons.done, color: Colors.white, size: 18);
    }
  }


  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    Color bubbleColor = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Colors.blue
        : Colors.green;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                _copyToClipboard(data['message']);
                Fluttertoast.showToast(msg: 'Message copied to clipboard');
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 300, // Set a maximum width for the message bubble
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: bubbleColor,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['messageType'] == MessageType.audio.index)
                            _buildAudioMessage(data['message'])
                          else if (data['messageType'] == MessageType.image.index)
                            _buildImageFromFirestore(data['message'])
                          else
                            Text(
                              data['message'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      _formatTimestamp(data['timestamp']),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    SizedBox(width: 5),
                    if (data['senderId'] == _firebaseAuth.currentUser!.uid)
                      _buildStatusIcon(data),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }



  Widget _buildAudioMessage(String audioPath) {
    return GestureDetector(
      onTap: () {
        // Play the audio message
        _playAudioMessage(audioPath);
      },
      child: Row(
        children: [
          Icon(Icons.play_arrow, color: Colors.white),
          SizedBox(width: 5),
          Text('Tap to play', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }


  void _playAudioMessage(String audioPath) async {
    try {
      if (audioPath != null && audioPath.isNotEmpty) {
        await audioPlayer.play(UrlSource(audioPath), volume: 40);
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }




  Widget _buildImageFromFirestore(String imageUrl) {
    print('_buildImageFromFirestore called with $imageUrl');

    String encodedUrl = Uri.encodeComponent(imageUrl);
    print('Encoded URL: $encodedUrl');

    return GestureDetector(
        onLongPress: () {
      _showImageDownloadDialog(imageUrl);
    },
    child: Image.network(
      Uri.decodeFull(encodedUrl),
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          // Image is fully loaded
          print('Image fully loaded');
          return child;
        } else {
          // Display a loading indicator while the image is loading
          print('Loading progress: ${loadingProgress
              .cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}');
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        }
      },
      errorBuilder: (BuildContext context, Object error,
          StackTrace? stackTrace) {
        // Custom error handling logic can be added here
        // You can return a custom error UI
        print('Error loading image: $error');
        return Container(
          width: 200,
          height: 200,
          color: Colors.grey, // You can customize the background color
          child: Center(
            child: Text('Error loading image'),
          ),
        );
      },
    )
    );
  }
  void _showImageDownloadDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<bool>(
          future: _downloadImage(imageUrl),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return AlertDialog(
              title: Text('Download Image?'),
              content: Text('Do you want to download this image?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Check if the image was successfully downloaded
                    if (snapshot.hasData && snapshot.data == true) {
                      print('Image downloaded successfully');
                      // Add your additional logic here
                    } else {
                      print('Failed to download image.');
                      // Handle failure
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Download'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<bool> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Save the image to the gallery
        final filePath = await _saveImageToGallery(bytes);

        print('Image saved to gallery: $filePath');

        // Show the success AlertDialog
        _showSuccessDialog();

        // Return true to indicate success
        return true;
      } else {
        print('Failed to download image. Status code: ${response.statusCode}');
        // Return false to indicate failure
        return false;
      }
    } catch (e, stackTrace) {
      print('Error downloading image: $e');
      print(stackTrace);
      // Return false to indicate failure
      return false;
    }
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download Successful'),
          content: Text('Image downloaded successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _saveImageToGallery(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = await File('${tempDir.path}/temp_image.png').create();

      // Write the image data to the file
      await tempFile.writeAsBytes(bytes);

      // Save the image to the gallery
      await GallerySaver.saveImage(tempFile.path);

      return tempFile.path; // Return the file path
    } catch (e) {
      print('Error saving image to gallery: $e');
      return ''; // Handle error and return an appropriate value
    }
  }


  void _copyToClipboard(String message) {
    Clipboard.setData(ClipboardData(text: message));
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);
    return formattedTime;
  }


  Future<void> startRecording() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Start recording...');

      final directory = await getApplicationDocumentsDirectory();
      audioPath = '${directory.path}/audio_${DateTime.now()}.aac';

      try {
        await audioRecorder.start(
          const RecordConfig(),
          path: audioPath,
        );

        setState(() {
          isRecording = true;
        });

        print('Recording started successfully');
      } catch (e, stackTrace) {
        print('Error starting recording: $e');
        print(stackTrace);
        // Handle the error as needed
      }
    }
  }

  Future<void> stopRecording() async {
    print('Stop recording...');

    try {
      await audioRecorder.stop();

      setState(() {
        isRecording = false;
      });

      print('Recording stopped successfully');

      // Send the recorded audio message
      if (audioPath.isNotEmpty) {
        await _chatService.sendAudioMessage(
          widget.receiverUserID,
          audioPath,
          MessageType.audio,
        );
        print('Audio message sent successfully');
      }
    } catch (e, stackTrace) {
      print('Error stopping recording: $e');
      print(stackTrace);
      // Handle the error as needed
    }
  }


  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showImageOptions(),
            icon: Icon(Icons.image),
          ),
          IconButton(
            onPressed: () {
              if (isRecording) {
                stopRecording();
              } else {
                startRecording();
              }
            },
            icon: Icon(isRecording ? Icons.stop : Icons.mic),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                obscureText: false,
                style: TextStyle(fontSize: 18, color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter Message",
                  hintStyle: TextStyle(fontSize: 18, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  fillColor: Colors.grey[100],
                  filled: true,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: Icon(
              Icons.arrow_upward,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }


  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      String imagePath = pickedFile.path;
      String imageUrl = await _uploadImageToStorage(imagePath);
      await _chatService.sendMessage(
          widget.receiverUserID, imageUrl, MessageType.image);
    }
  }

  Future<String> _uploadImageToStorage(String imagePath) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference storageReference = storage.ref().child(
        'images/chat/${DateTime.now()}.png');
    UploadTask uploadTask = storageReference.putFile(
      File(imagePath),
      SettableMetadata(contentType: 'image/png'), // Set the content type
    );


    TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await snapshot.ref.getDownloadURL();
    print('Download URL: $downloadUrl');
    return downloadUrl;
  }


  void _handleNewMessage(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    if (data['messageType'] == MessageType.audio.index) {
      // Play the audio message
      _playAudioMessage(data['message']);
    }
    // Check if the message is sent by the current user or if it has already been seen
    if (data['senderId'] != _firebaseAuth.currentUser!.uid && !data['seen']) {
      _showNotification(widget.receiverUserEmail, data['message']);
      _playNotificationSound();

      // Update the 'seen' status of the received message
      _chatService.updateMessageSeenStatus(
          document.reference, _firebaseAuth.currentUser!.uid);
      ethereumService.sendMessage(data['message']);
    }
  }

  void fetchDataFromEthereum() async {
    List<String> messages = await ethereumService.getMessages();
    // Assuming you want to print each message
    messages.forEach((message) {
      print('Smart contract message: $message');
    });
  }

}

