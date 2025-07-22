import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twasol/screens/ForgotPassword.dart';
import 'package:twasol/screens/home.dart';
import 'package:twasol/screens/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:twasol/screens/FingerprintAuthPage.dart';
import 'package:crypto/crypto.dart';
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  static const String id = 'Login';

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String email = "";
  String pass = "";
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> updateUserOnlineStatus(bool online) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .update({"online": online});
      } else {
        print("User is not signed in.");
      }
    } catch (e) {
      print("Error updating online status: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      print(userCredential.user?.displayName);
      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }

  Future<void> authenticateWithFingerprint() async {
    try {
      bool authenticated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FingerprintAuthPage(
            auth: _auth,
            firestore: _firestore,
          ),
        ),
      );

      if (authenticated != null && authenticated) {
        User? currentUser = _auth.currentUser;

      }
    } catch (e) {
      print('Error during fingerprint authentication: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        updateUserOnlineStatus(true);
      } else {
        updateUserOnlineStatus(false);
      }
    });
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
                  Icons.message,
                  size: 100,
                  color: Colors.grey[800],
                ),
                SizedBox(
                  height: 70,
                ),
                Text(
                  "Welcome back you\'ve been missed!",
                  style: TextStyle(fontSize: 18),
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
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: "Enter Email",
                    hintStyle: TextStyle(
                        fontFamily: 'Rene',
                        fontSize: 22,
                        color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  onChanged: (value) {
                    pass = value;
                  },
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: "Enter Password",
                    hintStyle: TextStyle(
                        fontFamily: 'Rene',
                        fontSize: 22,
                        color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                  padding: EdgeInsets.only(left: 200),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pushNamed(context, ForgotPassword.id);
                      });
                    },
                    child: Text(
                      "Forget password?",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          fontFamily: 'Rene'),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: 400,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape:
                          MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32.0)),
                          ),
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(fontSize: 22),
                        ),
                        onPressed: () async {
                          try {
                            final newUser =
                            await _auth.signInWithEmailAndPassword(
                                email: email, password: pass);

                            await updateUserOnlineStatus(true);

                            setState(() {
                              Navigator.pushReplacementNamed(
                                  context, Home.id);
                            });
                          } catch (e) {
                            print(e);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 80),
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            Navigator.pushNamed(context, Signup.id);
                          });
                        },
                        child: Text(
                          "Sign up",
                          style: TextStyle(fontSize: 20, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 0),
                  child: Text(
                    "Login with Google",
                    style: TextStyle(
                        fontSize: 22, color: Colors.black, fontFamily: "Rene"),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        try {
                          await signInWithGoogle();

                          await updateUserOnlineStatus(true);

                          setState(() {
                            Navigator.pushReplacementNamed(
                                context, Home.id);
                          });
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        backgroundImage: AssetImage('image/logo.google.jpg'),
                      ),
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        try {
                          await authenticateWithFingerprint();
                          await updateUserOnlineStatus(true);
                          Navigator.pushReplacementNamed(context, Home.id);
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                        ),
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
