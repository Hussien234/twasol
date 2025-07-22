import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FingerprintAuthPage extends StatefulWidget {
  const FingerprintAuthPage({Key? key, required this.auth, required this.firestore})
      : super(key: key);

  final FirebaseAuth auth; // Receive _auth from Signup
  final FirebaseFirestore firestore; // Receive _firestore from Signup

  @override
  _FingerprintAuthPageState createState() => _FingerprintAuthPageState();
}

class _FingerprintAuthPageState extends State<FingerprintAuthPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool isAuthenticated = false;

  Future<void> authenticateWithFingerprint() async {
    try {
      // Check if the device supports biometrics
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      // If biometrics are not available on this device, return early
      if (!canCheckBiometrics) {
        // Biometrics not available on this device
        // Handle this case accordingly
        return;
      }
      // Attempt fingerprint authentication
      isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate with fingerprint',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,//its make the page of the fingerprint doesnt pop up again
          biometricOnly: true,// prevents the use of other methods such as PIN or password.
        ),
      );
      // If authentication is successful, move to the next step
      if (isAuthenticated) {
        // Move to the next step if authentication is successful
        await _updateFingerprintStatus(true);
      } else {
        // Fingerprint authentication failed
        // Handle this case accordingly
        print('Fingerprint authentication failed.');
      }
    } catch (e) {
      // Handle errors during fingerprint authentication
      print('Error during fingerprint authentication: $e');
      isAuthenticated = false;
    } finally {
      // Always pop the navigator, even if authentication fails
      Navigator.pop(context, isAuthenticated);
    }
  }

  Future<void> _updateFingerprintStatus(bool hasFingerprint) async {
    try {
      // Retrieve the current user using widget.auth
      final user = widget.auth.currentUser;//user(email)
      // Check if the user is not null
      if (user != null) {
        // Check if the document exists before updating
        // Retrieve the user document from Firestore
        final DocumentSnapshot userDoc = await widget.firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Document exists, proceed with update
          // Update the 'hasFingerprint' field in the user document
          await widget.firestore.collection('users').doc(user.uid).update({
            'hasFingerprint': hasFingerprint,
          });
        } else {
          // Document does not exist, handle this case accordingly
          // User document not found in Firestore
          print('User document not found in Firestore.');
        }
      }
    } catch (e) {
      // Handle errors during the update process
      print('Error updating fingerprint status: $e');
      print('This might be okay if the document does not exist yet.');
    }
  }

  @override
  void initState() {
    super.initState();
    authenticateWithFingerprint();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fingerprint Authentication'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
        // You can replace this with your UI for the fingerprint authentication process
      ),
    );
  }
}

