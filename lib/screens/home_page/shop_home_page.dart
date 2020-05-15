import 'dart:async';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/home_page/shop_completed_orders.dart';
import 'package:app/screens/home_page/shop_pending_orders.dart';
import 'package:app/screens/home_page/shop_scheduled_orders.dart';
import 'package:app/screens/shop_page/add_inventory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badges/badges.dart';

import '../../fonts.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}

class ShopHomePage extends StatefulWidget {
  ShopHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ShopHomePageState createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  int currentPage = 0;
  String currentTitle = "Home";
  String userUID;

  bool userLoaded = false;
  bool timeSlotsLoaded = false;

  String profilePicUrl;
  String userEmail;

  DocumentSnapshot userData;

  GeoHasher gH = GeoHasher();

  String token;

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController _dataController = TextEditingController();

  List<String> timeSlots;

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  void setUserData(String uid) async {
    token = await FirebaseNotifications().setUpFirebase();
    await Firestore.instance
        .collection('shops')
        .document(uid)
        .get()
        .then((data) {
      userData = data;
    });
    setState(() {
      userLoaded = true;
    });

  }


  Widget addressView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
            leading: Icon(Icons.add_location),
            subtitle: Text(userData['shop_address'],
                style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
      )),
    );
  }

  Widget buildHomeShop() {
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          addressView(),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("You are signed in as " + userData['shop_name'], style:TextStyle(
                fontSize: 18,
                fontFamily: AppFontFamilies.mainFont)),
          ),
          dashboardGrid()
    ]));
  }

  Widget dashboardGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: (3 / 4),
          children: [
            Card(
              child: Container(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Scheduled Orders",
                            style: TextStyle(
                                fontSize: 24,
                                fontFamily: AppFontFamilies.mainFont)),
                      )),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0,0, 32),
                        child: RaisedButton(
                            color: Theme.of(context).accentColor,
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0),
                            ),
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScheduledOrders(userData: userData,)));
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Check", style: TextStyle(color: Colors.white,
                                      fontFamily: AppFontFamilies.mainFont)),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white)
                              ]
                            )
                            ),
                        ),
                      ),
                ],
              )),
            ),
            Card(
              child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Pending Orders",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0,0, 32),
                          child: RaisedButton(
                              color: Theme.of(context).accentColor,
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopPendingOrders(userData: userData,)));
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Check", style: TextStyle(color: Colors.white,
                                          fontFamily: AppFontFamilies.mainFont)),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white)
                                  ]
                              )
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
            Card(
              child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Completed Orders",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0,0, 32),
                          child: RaisedButton(
                              color: Theme.of(context).accentColor,
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopCompletedOrders(userData: userData,)));
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Check", style: TextStyle(color: Colors.white,
                                          fontFamily: AppFontFamilies.mainFont)),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white)
                                  ]
                              )
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
            Card(
              child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Shop Profile",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0,0, 32),
                          child: RaisedButton(
                              color: Theme.of(context).accentColor,
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                              onPressed: (){
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Check", style: TextStyle(color: Colors.white,
                                          fontFamily: AppFontFamilies.mainFont)),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white)
                                  ]
                              )
                          ),
                        ),
                      ),
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    FirebaseAuth.instance.currentUser().then((user) {
      setUserData(user.uid);
      setState(() {
        profilePicUrl = user.photoUrl;
        userEmail = user.email;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
        ),
      ),
      body: userLoaded
          ? buildHomeShop()
          : Center(child: CircularProgressIndicator()),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
