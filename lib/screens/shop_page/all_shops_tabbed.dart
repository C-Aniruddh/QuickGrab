import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:app/screens/cart/cart_page.dart';
import 'package:app/screens/shop_page/tabbed_shop_parge.dart';
import 'package:badges/badges.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/screens/home_page/user_home_page.dart';
import 'package:app/screens/utils/custom_sliver_appbar_delegate.dart';
import 'package:app/screens/utils/custom_responsive_grid.dart';
import 'package:latlong/latlong.dart';

import '../../fonts.dart';

class AllShopsTabbed extends StatefulWidget {
  AllShopsTabbed({Key key, this.userDetails}) : super(key: key);

  final DocumentSnapshot userDetails;

  @override
  _AllShopsTabbedState createState() => _AllShopsTabbedState();
}

class _AllShopsTabbedState extends State<AllShopsTabbed> {

  final TextEditingController _textEditingController =
      new TextEditingController();

  List categories;

  bool userLoaded = true;

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


  @override
  void initState() {
    setState(() {
      categories = getCategories();
    });
    super.initState();
  }

  _showInformationDialog(BuildContext context, String text) {
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
                  'Okay',
                ),
              ),
            ],
          );
        });
  }
  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text,
                    style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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

  String distanceBetweenNumber(String shopGeoHash) {
    String userGeoHash = widget.userDetails['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();

    double meter = distance(LatLng(shopCoordinates[1], shopCoordinates[0]),
        LatLng(userCoordinates[1], userCoordinates[0]));

    return meter.round().toString();
  }

  double distanceBetweenDouble(String shopGeoHash) {
    String userGeoHash = widget.userDetails['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();
    double meter = distance(new LatLng(shopCoordinates[1], shopCoordinates[0]),
        new LatLng(userCoordinates[1], userCoordinates[0]));

    return meter;
  }

  List<DocumentSnapshot> filterByDistance(List<DocumentSnapshot> allDocs) {
    List<DocumentSnapshot> toReturn = [];
    for (var i = 0; i < allDocs.length; i++) {
      if (double.parse(distanceBetweenNumber(allDocs[i]['shop_geohash'])) <
          10000) {
        toReturn.add(allDocs[i]);
      } else {
        // do nothing
      }
    }

    toReturn.sort((a, b) => distanceBetweenDouble(a['shop_geohash'])
        .compareTo(distanceBetweenDouble(b['shop_geohash'])));

    return toReturn;
  }

  getStream(category, lower, upper){
    if (widget.userDetails['is21']){
      if (category == "All Shops"){
        return Firestore.instance
            .collection('shops')
            .where("shop_geohash", isGreaterThanOrEqualTo: lower)
            .where("shop_geohash", isLessThanOrEqualTo: upper)
            .where('paymentHold', isEqualTo: false)
            .where('verificationHold', isEqualTo: false)
            .snapshots();
      } else {
          return Firestore.instance
            .collection('shops')
              .where('industry', isEqualTo: category)
            .where("shop_geohash", isGreaterThanOrEqualTo: lower)
            .where("shop_geohash", isLessThanOrEqualTo: upper)
            .where('paymentHold', isEqualTo: false)
            .where('verificationHold', isEqualTo: false)
            .snapshots();
      }
    } else {
      if (category == "All Shops"){
        return Firestore.instance
            .collection('shops')
            .where('industry', whereIn: _industryListNoLiqour)
            .where("shop_geohash", isGreaterThanOrEqualTo: lower)
            .where("shop_geohash", isLessThanOrEqualTo: upper)
            .where('paymentHold', isEqualTo: false)
            .where('verificationHold', isEqualTo: false)
            .snapshots();
      } else {
        return Firestore.instance
            .collection('shops')
            .where('industry', isEqualTo: category)
            .where("shop_geohash", isGreaterThanOrEqualTo: lower)
            .where("shop_geohash", isLessThanOrEqualTo: upper)
            .where('paymentHold', isEqualTo: false)
            .where('verificationHold', isEqualTo: false)
            .snapshots();
      }
    }
  }

  List<String> calculateFilter() {
    if (userLoaded) {
      double addLat = widget.userDetails['lat'];
      double addLon = widget.userDetails['lon'];
      print(addLat);
      print(addLon);
      num queryDistance = 8000.round();

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

  String distanceBetween(String shopGeoHash) {
    String userGeoHash = widget.userDetails['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();
    double meter = distance(new LatLng(shopCoordinates[1], shopCoordinates[0]),
        new LatLng(userCoordinates[1], userCoordinates[0]));

    if (meter.round() > 1000) {
      return (meter.round() / 1000).toString() + " kms away";
    }
    return meter.round().toString() + " meters away";
  }

  Widget productGridView(String category) {
    List<String> upperLower = calculateFilter();
    String upper = upperLower[0];
    String lower = upperLower[1];

    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: getStream(category, lower, upper),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                ),
              );
            default:
              List<DocumentSnapshot> filterList = snapshot.data.documents;
              if (filterList.length < 1) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 96.0, 16.0, 16.0),
                    child: Text(
                        "There are no products in this category available."),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                  child: ResponsiveGridList(
                    desiredItemWidth: 150,
                    minSpacing: 8,
                    children: filterList
                        .map(
                          (item) => Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  child: Image.network(
                                    item.data['shop_image'],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      8.0, 12.0, 8.0, 4.0),
                                  child: Text(
                                    item.data['shop_name'],
                                    style: TextStyle(fontSize: 16.0),
                                    maxLines: 3,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Text(
                                    distanceBetween(
                                        item.data['shop_geohash']).toString(),
                                    style: TextStyle(fontSize: 16.0),
                                    maxLines: 2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                                  child: OutlineButton(
                                    // icon: Icon(Icons.add_shopping_cart),
                                    shape: StadiumBorder(),
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                    ),
                                    child: Text(
                                      "View Store",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ShopPage(
                                                  shopDetails: item,
                                                  userDetails: widget.userDetails)));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }
          }
        },
      ),
    );
  }


  Widget cartIcon(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('cart')
            .document(widget.userDetails.documentID)
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
                                userData: widget.userDetails,
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
                    fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
            child: new IconButton(
              icon: Icon(Icons.shopping_cart,
                  color: Theme.of(context).accentColor),
              onPressed: () async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CartPage(
                              userData: widget.userDetails,
                            )));
              },
            ),
          );
        });
  }


  getCategories() {
    if (widget.userDetails['is21']){
      return <String>[
        'All Shops',
        'Grocery',
        'Vegetables and Fruits',
        'Liquor',
        'Agriculture',
        'Oil and Gas',
        'Pharmaceuticals',
        'Retail',
        'Stationary',
        'Manufacturing',
        'Other'
      ];
    } else {
      return <String>[
        'All Shops',
        'Grocery',
        'Vegetables and Fruits',
        'Agriculture',
        'Oil and Gas',
        'Pharmaceuticals',
        'Retail',
        'Stationary',
        'Manufacturing',
        'Other'
      ];
    }

  }

  Widget tabWidget(String category) {
    return SingleChildScrollView(
      // child: buildProductGrid(category),
      child: productGridView(category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      body: DefaultTabController(
        length: categories.length,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: Text(
                  "Stores near you",
                  style: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
                actions: [cartIcon(context), SizedBox(width: 10)],
                expandedHeight: 250.0,
                elevation: 0,
                floating: false,
                pinned: true,
                iconTheme: IconThemeData(color: Colors.orange),
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Container(
                    child: Text(
                      "Stores near you",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        height: 250,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverAppBarDelegate(
                  TabBar(
                      isScrollable: true,
                      indicatorColor: Theme.of(context).hintColor,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: categories
                          .map((category) => Tab(text: category))
                          .toList()),
                ),
              )
            ];
          },
          body: TabBarView(
            children:
                categories.map((category) => tabWidget(category)).toList(),
          ),
        ),
      ),
    );
  }
}
