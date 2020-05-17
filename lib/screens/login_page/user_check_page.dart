import 'package:app/screens/home_page/shop_home_page.dart';
import 'package:app/screens/home_page/user_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/sign_up/signup_page.dart';
import 'package:app/screens/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../fonts.dart';

class UserCheckPage extends StatefulWidget {
  UserCheckPage({Key key, this.uid}) : super(key: key);

  final String uid;

  @override
  _UserCheckPageState createState() => _UserCheckPageState();
}

class _UserCheckPageState extends State<UserCheckPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.collection('uid_type').document(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if(snapshot.data.exists){
            DocumentSnapshot userDoc = snapshot.data;
            if (userDoc['type'] == "user") {
              return UserHomePage(title: "None");
            }
            return ShopHomePage(title: "None");
          } else {
            return Scaffold(
              appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Text("QuickGrab",
                        style: TextStyle(
                            fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
                  ),),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("You do not have an account. Please continue to sign up.",
                      style: TextStyle(fontSize: 24), textAlign: TextAlign.center),
                    ),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(
                              color: Colors.orangeAccent)),
                      onPressed: () {
                        _signOut();
                      },
                      color: Colors.orangeAccent,
                      textColor: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          "Continue to Sign Up",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                )
              ),
            );
          }
        } else {
          return Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text("Please wait while we load your account...")
                ],
              ),
            ),
          );
        }
      },
    );
  }
}