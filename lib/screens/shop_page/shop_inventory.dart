/*
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../fonts.dart';

class ShopInventory extends StatefulWidget {
  ShopInventory({Key key, this.shopData}) : super(key: key);

  final DocumentSnapshot shopData;

  @override
  _ShopInventoryState createState() => _ShopInventoryState();
}

class _ShopInventoryState extends State<ShopInventory> {
  DocumentSnapshot inventoryData;

  bool inventoryLoaded = false;

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();

  _showCompleteDialog(BuildContext context, String documentID, String otp) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                  child: Column(
                children: <Widget>[
                  //PhoneAuthWidgets.subTitle("Enter OTP"),
                  //PhoneAuthWidgets.textField(otpController),
                ],
              )),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () async {
                  if (otpController.text == otp) {
                    await Firestore.instance
                        .collection('appointments')
                        .document(documentID)
                        .updateData({'appointment_status': 'completed'}).then(
                            (value) async {
                      await Firestore.instance
                          .collection('appointments')
                          .document(documentID)
                          .get()
                          .then((doc) async {
                        var title = "Apopintment completed";
                        var body = "Your appointment at " +
                            doc['shop_name'] +
                            " was marked completed";
                        await Firestore.instance
                            .collection('notifications')
                            .add({
                          'sender_type': "shops",
                          'receiver_uid': doc['shopper_uid'],
                          'title': title,
                          'body': body,
                        });
                      });
                    });
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    _showInfoDialog(context, "The entered OTP is wrong");
                  }
                },
                child: Text(
                  'Yes',
                ),
              ),
            ],
          );
        });
  }

  _showErrorDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Text("Something went wrong, please try again."),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                },
                child: Text(
                  'Try Again',
                ),
              ),
              FlatButton(
                onPressed: () {
                },
                child: Text(
                  'Back',
                ),
              ),
            ],
          );
        });
  }

  void setUserData(String uid) async {
    try {
      await Firestore.instance
          .collection('inventory')
          .document(widget.shopData.documentID)
          .get()
          .then((data) {
        inventoryData = data;
      });
      setState(() {
        inventoryLoaded = true;
      });
    } catch (e) {
      _showErrorDialog(context);
    }
  }

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OKAY',
                ),
              ),
            ],
          );
        });
  }

  Widget buildNearbyGrid() {
    List<String> upperLower = calculateFilter();
    String upper = upperLower[0];
    String lower = upperLower[1];

    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('shops')
              .where("shop_geohash", isGreaterThanOrEqualTo: lower)
              .where("shop_geohash", isLessThanOrEqualTo: upper)
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
                List<DocumentSnapshot> filterList = filterByDistance(snapshot.data.documents);
                if (filterList.length < 1) {
                  return Center(
                    child: Text("There are no shops around you."),
                  );
                } else {
                  return SizedBox(
                    height: 400,
                    child: GridView.builder(
                      itemCount: filterList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2),
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(filterList[index].data['shop_name'].toString(), style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                                      )),
                                  Align(alignment: Alignment.bottomLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(distanceBetween(filterList[index].data['shop_geohash']) +
                                            " meters away", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                                      )),
                                ],
                              )
                          ),
                        );
                      },
                    ),
                  );
                }
            }
          },
        ));
  }

  Widget buildBody() {

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
            child: Text("Pending Orders",
                style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
          ),
        ),
        body: Container()
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
*/