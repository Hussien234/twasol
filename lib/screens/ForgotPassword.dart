import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:twasol/screens/login.dart';
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);
  static const String id='forgotpassword';
  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController forgetPasswordController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: SafeArea(
          child:Scaffold(
            backgroundColor: Colors.grey[300],
            body:
            Container(

              child: Column(
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    Icon(
                      Icons.email,
                      size: 130,
                      color: Colors.grey[800],
                    ),
                    Container(
                        margin: EdgeInsets.only(top: 100),
                        child: Center(child: Text("Receive an email to reset your password",
                          style: TextStyle(fontSize: 35,color:Colors.black,fontFamily: 'Rene'),textAlign: TextAlign.center,),)
                    ),
                    SizedBox(height: 40,),
                    TextField(
                      controller: forgetPasswordController,
                      onChanged: (value){

                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                            Icons.email_outlined
                        ),
                        hintText: "Enter Email",
                        hintStyle: TextStyle(fontFamily:'Rene',fontSize:22,color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue,width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                          fillColor: Colors.grey[100],
                          filled: true
                      ),
                    ),

                    SizedBox(height: 40,),
                    SizedBox(
                      width: 400,
                      height: 50,
                      child:ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.blue),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),),
                        ),
                        child: Text("Reset password" , style: TextStyle(fontSize: 22,color: Colors.white),),
                        onPressed:()async{
                          setState(() {
                            var forgetEmail=forgetPasswordController.text.trim();
                            try{
                              FirebaseAuth.instance.sendPasswordResetEmail(email: forgetEmail).then((value) =>
                              {
                                print("Email sent"),
                                Navigator.pushNamed(context, Login.id)
                              });
                            }on FirebaseAuthException catch(e){
                              print("Error$e");
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('password has been reseted '),
                              ),
                            );
                          });

                        },
                      ),
                    ),

                  ]
              ),
            ),
          ),
        )
    );
  }
}

