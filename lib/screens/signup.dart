import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:twasol/screens/home.dart';
import 'package:twasol/screens/login.dart';
import 'package:twasol/screens/FingerprintAuthPage.dart';
import 'package:crypto/crypto.dart';
class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);
  static const String id = 'Signup';

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  String name = "";
  String email = "";
  String pass = "";

  Future<void> signUp() async {
    try {
      final newUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // Generate a fingerprint identifier


      // Store additional user information in Firestore, including the fingerprint
      await _firestore.collection('users').doc(newUser.user!.uid).set({
        'uid': newUser.user!.uid,
        'name': name,
        'email': email,
        'hasFingerprint': true,
      });

      // Authenticate with fingerprint after successful signup
      await authenticateWithFingerprint(newUser.user!);

      Navigator.pushNamed(context, Home.id);
    } catch (e) {
      print(e);
    }
  }



  Future<void> authenticateWithFingerprint(User user) async {
    try {
       await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FingerprintAuthPage(
            auth: _auth, // Pass _auth to FingerprintAuthPage
            firestore: _firestore, // Pass _firestore to FingerprintAuthPage
          ),
        ),
      );

    } catch (e) {
      print('Error during fingerprint authentication: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[300],
          body: Container(
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                ),
                Icon(
                  Icons.account_box,
                  size: 140,
                  color: Colors.grey[800],
                ),
                SizedBox(
                  height: 50,
                ),
                Text(
                  "Let's create an account for you!",
                  style: TextStyle(fontSize: 21),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  onChanged: (value) {
                    name = value;
                  },
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter Username',
                    hintStyle: TextStyle(
                      fontFamily: 'Rene',
                      fontSize: 22,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 3.0),
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                TextField(
                  onChanged: (value) {
                    email = value;
                  },
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Enter Email',
                    hintStyle: TextStyle(
                      fontFamily: 'Rene',
                      fontSize: 22,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 3.0),
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                TextField(
                  onChanged: (value) {
                    pass = value;
                  },
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Enter Password',
                    hintStyle: TextStyle(
                      fontFamily: 'Rene',
                      fontSize: 22,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 3.0),
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: SizedBox(
                    width: 400,
                    height: 50,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                      ),
                      child: Text(
                        "Sign up",
                        style: TextStyle(fontSize: 22),
                      ),
                      onPressed: () async {
                        // Show a dialog to choose the authentication method
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Choose Authentication Method"),
                              content: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Navigate to fingerprint authentication
                                      Navigator.pop(context);
                                      signUp();
                                    },
                                    child: Text("Fingerprint"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Proceed with traditional signup
                                      Navigator.pop(context);
                                      signUp();
                                    },
                                    child: Text("Traditional"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 50),
                      child: Text(
                        "Already have an account?",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          Navigator.pushNamed(context, Login.id);
                        });
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
