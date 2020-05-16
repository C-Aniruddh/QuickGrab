import 'dart:async';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong/latlong.dart';
import 'package:quiver/iterables.dart';

import '../fonts.dart';
import 'cart/cart_page.dart';
import 'notifications_view/notifications_view.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool userLoaded = true;
  bool itemsLoaded = false;

  List<DocumentSnapshot> shopsNearby = [];
  List<DocumentSnapshot> productsFromShops = [];

  List<String> _industryListNoLiqour = <String>[
    'Agriculure',
    'Grocery',
    'Manufacturing',
    'Oil and Gas',
    'Pharmaceuticals',
    'Retail',
    'Stationary',
    'Vegetables and Fruits',
    'Other'
  ];

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  List<String> calculateFilter() {
    if (userLoaded) {
      double addLat = widget.userData['lat'];
      double addLon = widget.userData['lon'];
      print(addLat);
      print(addLon);
      num queryDistance = 200000.round();

      final Distance distance = const Distance();
      //final num query_distance = (EARTH_RADIUS * PI / 4).round();

      final p1 = new LatLng(addLat, addLon);
      final upperP = distance.offset(p1, queryDistance, 45);
      final lowerP = distance.offset(p1, queryDistance, 220);

      print(upperP);
      print(lowerP);

      GeoHasher geoHasher = GeoHasher();

      String lower = geoHasher.encode(lowerP.longitude, lowerP.latitude);
      String upper = geoHasher.encode(upperP.longitude, upperP.latitude);

      List<String> upperLower = [];
      upperLower.add(upper);
      upperLower.add(lower);
      return upperLower;
    } else {
      return [];
    }
  }

  String distanceBetweenNumber(String shopGeoHash) {
    String userGeoHash = widget.userData['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();
    double meter = distance(new LatLng(shopCoordinates[1], shopCoordinates[0]),
        new LatLng(userCoordinates[1], userCoordinates[0]));

    return meter.round().toString();
  }


  loadDocuments(){
    List<String> upperLower = calculateFilter();
    String upper = upperLower[0];
    String lower = upperLower[1];

    if(widget.userData.data['is21']){
      Firestore.instance.collection('shops')
        .where("shop_geohash", isGreaterThanOrEqualTo: lower)
        .where("shop_geohash", isLessThanOrEqualTo: upper)
        .getDocuments()
          .then((documents){
            shopsNearby = documents.documents;
      });
    } else {
      Firestore.instance
          .collection('shops')
          .where('industry', whereIn: _industryListNoLiqour)
          .where("shop_geohash", isGreaterThanOrEqualTo: lower)
          .where("shop_geohash", isLessThanOrEqualTo: upper)
          .getDocuments()
          .then((documents){
            shopsNearby = documents.documents;
      });
  }
    List<String> shopUIDs = [];
    for (var i=0; i < shopsNearby.length; i++){
      shopUIDs.add(shopsNearby[i].documentID);
    }

    var chunks = partition(shopUIDs, 10).toList();

    for (var j = 0; j < chunks.length; j ++){
      Firestore.instance.collection('products')
          .where('shop_uid', whereIn: chunks[j])
          .getDocuments()
          .then((documents){
        productsFromShops.addAll(documents.documents);
      });
    }

    setState(() {
      itemsLoaded = true;
    });

  }
  Widget notificationIcon(BuildContext context) {
    if (userLoaded) {
      return new StreamBuilder(
          stream: Firestore.instance
              .collection('notifications')
              .where('receiver_uid', isEqualTo: widget.userData.documentID)
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
                              NotificationsView(userData: widget.userData)));
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
                              NotificationsView(userData: widget.userData)));
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
                                NotificationsView(userData: widget.userData)));
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
                  builder: (context) => NotificationsView(userData: widget.userData)));
        },
      );
    }
  }

  Widget cartIcon(BuildContext context) {
    if (userLoaded) {
      return new StreamBuilder(
          stream: Firestore.instance
              .collection('cart')
              .document(widget.userData.documentID)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Badge(
                badgeContent: Text("0",
                    style: TextStyle(
                        fontFamily: AppFontFamilies.mainFont,
                        color: Colors.white)),
                child: new IconButton(
                  icon: Icon(Icons.shopping_cart,
                      color: Theme.of(context).accentColor),
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CartPage(
                              userData: widget.userData,
                            )));
                  },
                ),
              );
            }
            var userDocument = snapshot.data['cart'];
            return new Badge(
              position: BadgePosition.topRight(right: 4, top: 4),
              badgeContent: Text(userDocument.length.toString(),
                  style: TextStyle(
                      fontFamily: AppFontFamilies.mainFont,
                      color: Colors.white)),
              child: new IconButton(
                icon: Icon(Icons.shopping_cart,
                    color: Theme.of(context).accentColor),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CartPage(
                            userData: widget.userData,
                          )));
                },
              ),
            );
          });
    } else {
      return new Badge(
        badgeContent: Text("0",
            style: TextStyle(
                fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
        child: new IconButton(
          icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
          onPressed: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CartPage(
                      userData: widget.userData,
                    )));
          },
        ),
      );
    }
  }

  Future<List<DocumentSnapshot>> search(String search) async {
    List<DocumentSnapshot> result = [];
    print("search");
    for (var i = 0; i < shopsNearby.length; i++){
      print(i);
      print(shopsNearby[i]);
      if (shopsNearby[i].data['shop_name'].toString().contains(search)){
        result.add(shopsNearby[i]);
      }
    }

    for (var i = 0; i < productsFromShops.length; i++){
      print(i);
      print(shopsNearby[i]);
      if (shopsNearby[i].data['shop_name'].toString().contains(search)){
        result.add(shopsNearby[i]);
      }
    }
    return result;
  }

  Widget buildSearchPage(){
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SearchBar<DocumentSnapshot>(
            onSearch: search,
          onItemFound: (DocumentSnapshot documentSnapshot, int index){
              return ListTile(
                title: Text("Document")
              );
          },
        ),
      )
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    loadDocuments();
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
            child: Text("Search",
                style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
          ),
          actions: <Widget>[
            notificationIcon(context),
            cartIcon(context),
            SizedBox(width: 10),
          ]),
      body: itemsLoaded ? buildSearchPage()
      : Center(
        child: CircularProgressIndicator(backgroundColor: Theme.of(context).accentColor,)
      )
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}