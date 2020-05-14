import 'package:app/screens/home_page/shop_home_page.dart';
import 'package:app/screens/home_page/user_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/sign_up/signup_page.dart';
import 'package:app/screens/home_page.dart';

class UserCheckPage extends StatefulWidget {
  UserCheckPage({Key key, this.uid}) : super(key: key);

  final String uid;

  @override
  _UserCheckPageState createState() => _UserCheckPageState();
}

class _UserCheckPageState extends State<UserCheckPage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.collection('uid_type').document(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          DocumentSnapshot userDoc = snapshot.data;
          if (userDoc['type'] == "user") {
            return UserHomePage(title: "None");
          }
          return ShopHomePage(title: "None");
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