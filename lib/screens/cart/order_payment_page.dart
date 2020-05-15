import 'dart:async';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/home_page/shop_completed_orders.dart';
import 'package:app/screens/home_page/shop_pending_orders.dart';
import 'package:app/screens/home_page/shop_scheduled_orders.dart';
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

class OrderPaymentPage extends StatefulWidget {
  OrderPaymentPage({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _OrderPaymentPageState createState() => _OrderPaymentPageState();
}

class _OrderPaymentPageState extends State<OrderPaymentPage> {
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

  Widget buildHomePayment() {
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Shop accepts payment through", style:TextStyle(
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
          childAspectRatio: (3 / 3),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                child: Badge(
                  position: BadgePosition.topLeft(),
                  badgeContent: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("P", style: TextStyle(
                        fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
                  ),
                  child: Container(
                      child: Align(
            alignment: Alignment.center,
            child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("PayTM",
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: AppFontFamilies.mainFont)),
            )),
            ),
                ),
              )),
            Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                  child: Badge(
                    position: BadgePosition.topLeft(),
                    badgeContent: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("C", style: TextStyle(
                          fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
                    ),
                    child: Container(
                      child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Cash",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                    ),
                  ),
                )),
            Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                  child: Badge(
                    position: BadgePosition.topLeft(),
                    badgeContent: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("C", style: TextStyle(
                          fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
                    ),
                    child: Container(
                      child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Credit / Debit Card",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                    ),
                  ),
                )),
            Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                  child: Badge(
                    position: BadgePosition.topLeft(),
                    badgeContent: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("G", style: TextStyle(
                          fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
                    ),
                    child: Container(
                      child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Google Pay / UPI",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: AppFontFamilies.mainFont)),
                          )),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
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
          }
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text("Payment",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildHomePayment()
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
