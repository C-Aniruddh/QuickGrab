import 'dart:async';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../fonts.dart';

class NotificationsView extends StatefulWidget {
  NotificationsView({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  Widget buildNearbyGrid() {
  /*
  *
  * 'sender_type': "shops",
                              'receiver_uid': doc['shopper_uid'],
                              'title': title,
                              'body': body,
                              'read': false,
  * */
    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('notifications')
              .where("receiver_uid", isEqualTo: widget.userData.documentID)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> filterList = snapshot.data.documents;
                if (filterList.length < 1) {
                  return Center(
                    child: Text("You have no new notifications.", style: TextStyle(
                        fontFamily:
                        AppFontFamilies.mainFont)),
                  );
                } else {
                  return SizedBox(
                    child: ListView.separated(
                      separatorBuilder: (BuildContext cxtc, int index){
                        return Divider();
                      },
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filterList.length,
                      //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      //    crossAxisCount: 3, childAspectRatio: (4 / 6)),
                      itemBuilder: (BuildContext context, int index) {
                        return InkWell(
                            onTap: () {
                              Firestore.instance.collection('notifications')
                                  .document(filterList[index].documentID)
                                  .updateData({'read': true});
                            },
                            child:
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                leading: Icon(Icons.notifications),
                                  subtitle: Text(
                                      filterList[index].data['body'],
                                      style: TextStyle(
                                          fontFamily:
                                          AppFontFamilies.mainFont)),
                                  title: Text(
                                      filterList[index].data['title'],
                                      style: TextStyle(
                                          fontFamily:
                                          AppFontFamilies.mainFont)),
                                  trailing: filterList[index].data['read'] ?
                                  SizedBox(width: 10)
                                      :Badge(
                                    badgeContent: Text("NEW", style: TextStyle(
                                      color: Colors.white,
                                        fontFamily:
                                        AppFontFamilies.mainFont)),
                                  )
                              ),
                            )
                        );
                      },
                    ),
                  );
                }
            }
          },
        ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.close),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text("Notifications",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildNearbyGrid()
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}