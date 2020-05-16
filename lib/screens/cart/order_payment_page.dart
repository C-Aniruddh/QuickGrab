import 'dart:async';
import 'dart:math';
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
  OrderPaymentPage({Key key, this.userData, this.shopDetails, this.items}) : super(key: key);

  final DocumentSnapshot userData;
  final DocumentSnapshot shopDetails;
  var items;

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
            child: Text("Confirm your order", style:TextStyle(
                fontSize: 18,
                fontFamily: AppFontFamilies.mainFont)),
          ),
              orderConfirmView()
    ]));
  }


  _buildInvoiceContentCompressed(invoiceData) {
    List<Widget> columnContent = [];

    for (dynamic content in invoiceData) {
      List product_data = content['product'].values.toList();
      columnContent.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  content['product']['item_name'].toString(),
                  style: TextStyle(fontSize: 16.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      content['quantity'].toString(),
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Text(
                    "|",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      content['cost'].toString(),
                      style: TextStyle(fontSize: 16.0),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    }

    Column column = Column(
      children: columnContent,
    );

    return column;
  }

  String totalAmount(){
    double total = 0;

    for (var i = 0; i < widget.items.length; i++) {
      var item = widget.items[i];

      if (item['cost'] == "NA"){
        return "NA";
      }

      total = total +
          (int.parse(item['cost']) *
              int.parse(
                  item['quantity'].toString()));
    }

    return total.toString();
  }


  Widget orderConfirmView(){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  "Item",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Quantity",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Text(
                    "|",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Price",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        _buildInvoiceContentCompressed(widget.items),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width:
              MediaQuery.of(context).size.width * 0.4,
              child: Divider(
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  "Total",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Text(
                "|",
                style: TextStyle(fontSize: 16.0),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  totalAmount().toString(),
                  style: TextStyle(fontSize: 16.0),
                ),
              )
            ],
          ),
        ),
      ],
    );
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

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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
      body: buildHomePayment(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Container(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                  color: Color.fromRGBO(92, 92, 92, 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(32),
                    topRight: const Radius.circular(32),
                  )
              ),
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Container()
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: RaisedButton(
                        color: Theme.of(context).accentColor,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0),
                        ),
                        onPressed: () async {
                          _showInfoDialog(context, "Your order is being placed");
                          var rng = new Random();
                          var now = new DateTime.now();

                          List<String> shops = [];
                          for (var i = 0; i < widget.items.length; i ++) {
                            var item = widget.items[i];
                            String shop_uid = item['product']['shop_uid'];
                            if (!shops.contains(shop_uid)) {
                              shops.add(shop_uid);
                            }
                          }

                          for (var i = 0; i < shops.length; i ++) {
                            var orderItems = [];
                            for (var j = 0; j < widget.items.length; j++) {
                              var item = widget.items[j];
                              String shop_uid = item['product']['shop_uid'];
                              if (shop_uid == shops[i]) {
                                orderItems.add(item);
                              }
                            }

                            await Firestore.instance.collection('shops')
                                .document(shops[i])
                                .get()
                                .then((shopDoc) async {
                              await Firestore.instance.collection(
                                  'appointments')
                                  .add({'timestamp': now,
                                'items': orderItems,
                                'target_shop': shopDoc.data['uid'],
                                'shopper_uid': widget.userData['uid'],
                                'shopper_name': widget.userData['name'],
                                'shop_name': shopDoc.data['shop_name'],
                                'shop_geohash': shopDoc.data['shop_geohash'],
                                'appointment_status': 'pending',
                                'appointment_start': null,
                                'appointment_end': null,
                                'appointment_date': null,
                                'otp': (rng.nextInt(10000) + 1000).toString()
                              }).then((value) async {
                                String title = "New appointment request";
                                String body = widget.userData['name'] +
                                    " has requested an appointment.";
                                await Firestore.instance.collection(
                                    'notifications')
                                    .add({'sender_type': "users",
                                  'receiver_uid': shopDoc.data['uid'],
                                  'title': title,
                                  'body': body,
                                  'read': false,
                                });
                              });
                            });

                            await Firestore.instance.collection('cart')
                                .document(widget.userData.documentID)
                                .setData({'cart': []});

                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

                            // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPaymentPage(items: cartItems)));
                          }

                        },
                        child: ListTile(
                            title: Text("Complete Order", style: TextStyle(color: Colors.white, fontFamily: AppFontFamilies.mainFont)),
                            trailing: Icon(Icons.arrow_forward_ios, color: Colors.white,)
                        )
                    ),
                  )
                ],),
            )
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
