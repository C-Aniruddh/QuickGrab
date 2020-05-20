import 'dart:async';
import 'dart:io';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/home_page/shop_completed_orders.dart';
import 'package:app/screens/home_page/shop_pending_orders.dart';
import 'package:app/screens/home_page/shop_scheduled_orders.dart';
import 'package:app/screens/notifications_view/notifications_view.dart';
import 'package:app/screens/shop_page/add_inventory.dart';
import 'package:app/screens/home_page/shop_my_inventory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jiffy/jiffy.dart';
import 'package:universal_platform/universal_platform.dart';
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
    if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid){
      token = await FirebaseNotifications().setUpFirebase();
    }
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

    updateNotificationToken();
  }

  updateNotificationToken(){
    if (token == null){
      token = "none";
    }
    Firestore.instance.collection('shops')
        .document(userData.documentID)
        .updateData({'token': token});
  }

  Widget notificationIcon(BuildContext context) {
    if (userLoaded) {
      return new StreamBuilder(
          stream: Firestore.instance
              .collection('notifications')
              .where('receiver_uid', isEqualTo: userData.documentID)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData){
              return IconButton(
                icon: Icon(Icons.notifications,
                    color: Theme.of(context).accentColor),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              NotificationsView(userData: userData)));
                },
              );
            }
            if (snapshot.data.documents.length < 1) {
              return IconButton(
                icon: Icon(Icons.notifications,
                    color: Theme.of(context).accentColor),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              NotificationsView(userData: userData)));
                },
              );
            } else {
              return new Badge(
                position: BadgePosition.topRight(right: 4, top: 4),
                badgeContent: SizedBox(height: 20),
                child: new IconButton(
                  icon: Icon(Icons.notifications,
                      color: Theme
                          .of(context)
                          .accentColor),
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                NotificationsView(userData: userData)));
                  },
                ),
              );
            }
          });
    } else {
      return new IconButton(
        icon: Icon(Icons.notifications, color: Theme.of(context).accentColor),
        onPressed: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NotificationsView(userData: userData)));
        },
      );
    }
  }



  Widget addressView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
      child: Badge(
        position: BadgePosition.topLeft(top: 12),
        badgeColor: Theme.of(context).accentColor,
        badgeContent: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(Icons.add_location, color: Colors.white),
        ),
        child: SizedBox(
          height: 64,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16,0, 0, 8),
                child: ListTile(
                    title: Text(userData['shop_address'],
                      style: TextStyle(fontFamily: AppFontFamilies.mainFont), overflow: TextOverflow.ellipsis,)),
              )),
        ),
      ),
    );
  }

  Widget paymentHoldView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
      child: Badge(
        position: BadgePosition.topLeft(top: 12),
        badgeColor: Theme.of(context).accentColor,
        badgeContent: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(Icons.warning, color: Colors.white),
        ),
        child: SizedBox(
          height: 64,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16,0, 0, 8),
                child: ListTile(
                  trailing: FlatButton(child: Text("MORE INFO"), onPressed: (){

                  },),
                    title: Text("There is a problem with your payments.",
                      style: TextStyle(fontFamily: AppFontFamilies.mainFont), overflow: TextOverflow.ellipsis, maxLines: 2,)),
              )),
        ),
      ),
    );
  }

  Widget verificationHoldView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
      child: Badge(
        position: BadgePosition.topLeft(top: 12),
        badgeColor: Theme.of(context).accentColor,
        badgeContent: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(Icons.warning, color: Colors.white),
        ),
        child: SizedBox(
          height: 64,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16,0, 0, 8),
                child: ListTile(
                    trailing: FlatButton(child: Text("VERIFY"), onPressed: (){

                    },),
                    title: Text("Your shop has not been verified yet.",
                      style: TextStyle(fontFamily: AppFontFamilies.mainFont), overflow: TextOverflow.ellipsis, maxLines: 2,)),
              )),
        ),
      ),
    );
  }

  Widget buildHomeShop() {
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addressView(),
              Divider(),
              userData['verificationHold'] ? verificationHoldView() : SizedBox(height: 1),
              userData['verificationHold'] ? Divider() : SizedBox(height: 1),
              userData['paymentHold'] ? paymentHoldView() : SizedBox(height: 1),
              userData['paymentHold'] ? Divider() : SizedBox(height: 1),
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
                            child: Text("My Inventory",
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
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopMyInventory(userData: userData,)));
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

    SystemChannels.lifecycle.setMessageHandler((msg){
      debugPrint('SystemChannels> $msg');
      if(msg==AppLifecycleState.resumed.toString())setState((){});
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
        actions: [
          notificationIcon(context),
          IconButton(icon: Icon(Icons.power_settings_new, color: Theme.of(context).accentColor,),
            onPressed: (){
              _signOut();
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: userLoaded
          ? buildHomeShop()
          : Center(child: CircularProgressIndicator()),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
