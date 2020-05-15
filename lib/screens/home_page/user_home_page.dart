import 'dart:async';
import 'package:app/fonts.dart';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/appointments/appointments.dart';
import 'package:app/screens/cart/cart_page.dart';
import 'package:app/screens/notifications_view/notifications_view.dart';
import 'package:app/screens/shop_page/shop_page.dart';
import 'package:app/screens/utils/custom_dialog.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong/latlong.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share/share.dart';
import 'package:app/screens/user_options/rate_app.dart' as rateApp;

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

class UserHomePage extends StatefulWidget {
  UserHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  int currentPage = 0;
  String currentTitle = "Home";
  String userUID;

  bool userLoaded = false;
  bool timeSlotsLoaded = false;

  String profilePicUrl;
  String userEmail;

  DocumentSnapshot userData;

  List<DocumentSnapshot> offers;

  List<DocumentSnapshot> upcomingAppointments;
  int _current = 0;

  String token;

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController _dataController = TextEditingController();

  TextEditingController suggestionTextController = new TextEditingController();
  final suggestionformKey = GlobalKey<FormState>();

  void setUserData(String uid) async {
    token = await FirebaseNotifications().setUpFirebase();
    await Firestore.instance
        .collection('users')
        .document(uid)
        .get()
        .then((data) {
      userData = data;
    });

    await Firestore.instance.collection('offers').getDocuments().then((docs) {
      offers = docs.documents;
    });

    await Firestore.instance
        .collection('appointments')
        .where('shopper_uid', isEqualTo: userData['uid'])
        .where('appointment_status', isEqualTo: "scheduled")
        .getDocuments()
        .then((docs) {
      upcomingAppointments = docs.documents;
    });

    setState(() {
      userLoaded = true;
    });
  }

  List<String> calculateFilter() {
    if (userLoaded) {
      double addLat = userData['lat'];
      double addLon = userData['lon'];
      print(addLat);
      print(addLon);
      num queryDistance = 1000.round();

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
    String userGeoHash = userData['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();
    double meter = distance(new LatLng(shopCoordinates[1], shopCoordinates[0]),
        new LatLng(userCoordinates[1], userCoordinates[0]));
    return meter.round().toString();
  }

  List<DocumentSnapshot> filterByDistance(List<DocumentSnapshot> allDocs) {
    List<DocumentSnapshot> toReturn = [];
    for (var i = 0; i < allDocs.length; i++) {
      if (double.parse(distanceBetween(allDocs[i]['shop_geohash'])) < 1000) {
        toReturn.add(allDocs[i]);
      } else {
        // do nothing
      }
    }
    return toReturn;
  }

  String getCity(String address) {
    List<String> elements = address.split(',');
    String city = elements[elements.length - 3];
    return city.trim();
  }

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  Future<List<DocumentSnapshot>> search(String search) async {
    await Future.delayed(Duration(seconds: 2));
    List<DocumentSnapshot> result = [];
    Firestore.instance
        .collection('shops')
        .where('shop_name', isEqualTo: search)
        .getDocuments()
        .then((documents) {
      result = documents.documents;
    });
    return result;
  }

  buildOrderScheduledBanner(DocumentSnapshot appointment) {
    return Card(
        child: Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 8, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Order Scheduled for",
                  style: TextStyle(fontSize: 16.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.store_mall_directory,
                  color: Colors.orangeAccent,
                  size: 32.0,
                ),
                SizedBox(
                  width: 16.0,
                ),
                Text(
                  appointment.data['shop_name'],
                  style: TextStyle(fontSize: 18.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.orangeAccent,
                  size: 32.0,
                ),
                SizedBox(
                  width: 16.0,
                ),
                Text(
                  appointment.data['appointment_start'] +
                      " - " +
                      appointment.data['appointment_end'],
                  style: TextStyle(fontSize: 18.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget buildOrderScheduledCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
          enlargeCenterPage: false,
          enableInfiniteScroll: false,
          onPageChanged: (index, reason) {
            setState(() {
              _current = index;
            });
          }),
      items: upcomingAppointments.map((appointment) {
        return Builder(builder: (BuildContext context) {
          return Container(
            child: buildOrderScheduledBanner(appointment),
          );
        });
      }).toList(),
    );
  }

  Widget indicatorDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: upcomingAppointments.map((url) {
        int index = upcomingAppointments.indexOf(url);
        return Container(
          width: 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _current == index ? Colors.orange[700] : Colors.orange[50],
          ),
        );
      }).toList(),
    );
  }

  Widget buildHomeUser() {
    return SingleChildScrollView(
        child: Column(children: [
      addressView(),
      offers.length < 1 ? SizedBox(height: 1) : offersView(),
      Divider(),
      // upcomingAppointments.length < 1 ? SizedBox(height: 1) : buildOrderScheduledBanner(),
      //upcomingAppointments.length < 1 ? SizedBox(height: 1) : buildOrderScheduledCarousel(),
      //upcomingAppointments.length < 1 ? SizedBox(height: 1) : indicatorDots(),
      // upcomingAppointments.length < 1 ? SizedBox(height: 1) :  Divider(),
      userData['favorites'].length < 1 ? SizedBox(height: 1) : favoritesView(),
      nearbyView()
    ]));
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
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
            child: ListTile(
                title: Text(
              userData['address'],
              style: TextStyle(fontFamily: AppFontFamilies.mainFont),
              overflow: TextOverflow.ellipsis,
            )),
          )),
        ),
      ),
    );
  }

  Widget nearbyView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Stores near you",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: buildNearbyGrid(),
          )
        ]);
  }

  Widget offersView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Offers",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          SizedBox(
            height: 250,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    Firestore.instance
                        .collection('shops')
                        .document(offers[index].data['shop_uid'])
                        .get()
                        .then((doc) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ShopPage(
                                  shopDetails: doc, userDetails: userData)));
                    });
                  },
                  child: Card(
                    semanticContainer: true,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Image.network(
                      offers[index].data['image'],
                      fit: BoxFit.fill,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.all(5),
                  ),
                );
              },
              itemCount: offers.length,
              viewportFraction: 0.8,
              scale: 0.9,
            ),
          ),
        ]);
  }

  Widget favSingle(DocumentSnapshot document) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ShopPage(shopDetails: document, userDetails: userData)));
      },
      child: Card(
        child: Container(
          width: 160.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                    height: 120,
                    width: 160,
                    child: Hero(
                      tag: "none",
                      child: Image(
                          image: NetworkImage(document['shop_image']),
                          height: 128,
                          width: 128),
                    )),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: ListTile(
                        title: Text(document['shop_name'],
                            style: TextStyle(
                                fontFamily: AppFontFamilies.mainFont)),
                        subtitle: Text(
                            distanceBetween(document['shop_geohash']) +
                                " meters away",
                            style: TextStyle(
                                fontFamily: AppFontFamilies.mainFont)))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget favoritesView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Favourites",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SizedBox(
                height: 200,
                child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance
                      .collection('shops')
                      .where(FieldPath.documentId,
                          whereIn: userData['favorites'])
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return new Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Theme.of(context).accentColor,
                          ),
                        );
                      default:
                        List<DocumentSnapshot> documents = new List();
                        documents = (snapshot.data.documents);
                        if (documents.length < 1) {
                          return Center(
                            child: Text("You have no appointment requests.",
                                style: TextStyle(
                                    fontFamily: AppFontFamilies.mainFont)),
                          );
                        } else {
                          return new Container(
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: documents.length,
                                  itemBuilder: (BuildContext ctxt, int index) {
                                    DocumentSnapshot document =
                                        documents[index];
                                    return favSingle(document);
                                  }));
                        }
                    }
                  },
                )),
          ),
          Divider(),
        ]);
  }

  Widget cartIcon(BuildContext context) {
    if (userLoaded) {
      return new StreamBuilder(
          stream: Firestore.instance
              .collection('cart')
              .document(userData.documentID)
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
                                  userData: userData,
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
                                userData: userData,
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
                          userData: userData,
                        )));
          },
        ),
      );
    }
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
            List<DocumentSnapshot> filterList =
                filterByDistance(snapshot.data.documents);
            if (filterList.length < 1) {
              return Center(
                child: Text("There are no shops around you."),
              );
            } else {
              return SizedBox(
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filterList.length,
                  //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //    crossAxisCount: 3, childAspectRatio: (4 / 6)),
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShopPage(
                                    shopDetails: filterList[index],
                                    userDetails: userData)));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    filterList[index].data['shop_image']),
                              ),
                              subtitle: Text(
                                  distanceBetween(filterList[index]
                                          .data['shop_geohash']) +
                                      " meters away",
                                  style: TextStyle(
                                      fontFamily: AppFontFamilies.mainFont)),
                              title: Text(filterList[index].data['shop_name'],
                                  style: TextStyle(
                                      fontFamily: AppFontFamilies.mainFont)),
                              trailing: IconButton(
                                icon: Icon(Icons.arrow_forward_ios),
                                onPressed: () {},
                              )),
                        ),
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

  Widget buildHomeUser_Stores() {
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
            List<DocumentSnapshot> filterList =
                filterByDistance(snapshot.data.documents);
            if (filterList.length < 1) {
              return Center(
                child: Text("There are no shops around you."),
              );
            } else {
              return new Container(
                  child: ListView.builder(
                      itemCount: filterList.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        var document = filterList[index];
                        return Card(
                          margin: EdgeInsets.all(10.0),
                          elevation: 2,
                          child: Container(
                            child: new ListTile(
                              contentPadding: EdgeInsets.all(8),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ShopPage(
                                              shopDetails: document,
                                              userDetails: userData,
                                            )));
                              },
                              leading: Container(
                                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                  child: Text(document['shop_name'][0]
                                      .toString()
                                      .toUpperCase()),
                                ),
                              ),
                              title: Text(document['shop_name']),
                              subtitle: Text(
                                distanceBetween(document['shop_geohash']) +
                                    " meters away",
                              ),
                              trailing: IconButton(
                                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                icon: Icon(Icons.map),
                                onPressed: () {
                                  print("Open");
                                  MapUtils.openMap(document['shop_lat'],
                                      document['shop_lon']);
                                },
                              ),
                            ),
                          ),
                        );
                      }));
            }
        }
      },
    ));
  }

  _showModalAppointmentDetails(DocumentSnapshot document) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateSheet) =>
                  SingleChildScrollView(
                child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(Icons.info),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Appointment Details',
                                    style: TextStyle(fontSize: 16.0)),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(
                                    Icons.close,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.black26,
                        ),
                        SizedBox(
                            height: 300,
                            child: Container(
                                child: Column(
                              children: <Widget>[
                                Flexible(
                                  child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          16.0, 8.0, 16.0, 0),
                                      child: Column(
                                        children: <Widget>[
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                      child: Icon(Icons.lock),
                                                    ),
                                                    title: Text("OTP"),
                                                    subtitle:
                                                        Text(document['otp']),
                                                  ))),
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                      child: Icon(Icons.timer),
                                                    ),
                                                    title: Text("Start Time"),
                                                    subtitle: Text(document[
                                                            'appointment_start']
                                                        .toString()),
                                                  ))),
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                      child: Icon(Icons.timer),
                                                    ),
                                                    title: Text("End Time"),
                                                    subtitle: Text(document[
                                                            'appointment_end']
                                                        .toString()),
                                                  ))),
                                        ],
                                      )),
                                ),
                              ],
                            )))
                      ],
                    )),
              ),
            ));
  }

  // Appointments tab

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
                  product_data[3].toString(),
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

  Widget scheduledAppointments(DocumentSnapshot document, int total) {
    return Card(
      margin: EdgeInsets.all(10.0),
      elevation: 2,
      child: Container(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                document['shop_name'],
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        "Date:",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        document['appointment_data'] != null
                            ? document['appointment_data']
                            : "Pending",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        "OTP:",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        document['otp'],
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    "Time Slot:",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    document['appointment_start'] != null &&
                            document['appointment_end'] != null
                        ? document['appointment_start'] +
                            " - " +
                            document['appointment_end']
                        : "Pending",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
            Divider(
              color: Colors.grey,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Item",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            _buildInvoiceContentCompressed(document['items']),
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
                      total.toString(),
                      style: TextStyle(fontSize: 16.0),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppointmentsUser() {
    List<String> status = ['pending', 'scheduled'];
    return Container(
        child: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('appointments')
          .where('appointment_status', whereIn: status)
          .where('shopper_uid', isEqualTo: userData.documentID)
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
            List<DocumentSnapshot> documents = new List();
            documents = (snapshot.data.documents);
            if (documents.length < 1) {
              return Center(
                child: Text("You currently have no appointments."),
              );
            } else {
              return new Container(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    DocumentSnapshot document = documents[index];
                    int total = 0;
                    for (var i = 0; i < document['items'].length; i++) {
                      total = total + int.parse(document['items'][i]['cost']);
                    }
                    return scheduledAppointments(document, total);
                  },
                ),
              );
            }
        }
      },
    ));
  }

  _buildInvoiceContent(invoiceData) {
    List<Widget> columnContent = [];

    for (dynamic content in invoiceData) {
      List product_data = content['product'].values.toList();
      columnContent.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  product_data[3].toString(),
                  style: TextStyle(fontSize: 16.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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

  Widget buildAppointmentsDoneUser() {
    return Container(
        child: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('appointments')
          .where('appointment_status', isEqualTo: 'completed')
          .where('shopper_uid', isEqualTo: userData['uid'])
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
            List<DocumentSnapshot> documents = new List();
            documents = (snapshot.data.documents);
            if (documents.length < 1) {
              return Center(
                child: Text("You have never booked an appointment."),
              );
            } else {
              return new Container(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    DocumentSnapshot document = documents[index];
                    int total = 0;
                    for (var i = 0; i < document['items'].length; i++) {
                      total = total + int.parse(document['items'][i]['cost']);
                    }
                    return Card(
                      margin: EdgeInsets.all(10.0),
                      elevation: 2,
                      child: Container(
                        child: ExpansionTile(
                          title: Text(
                            document['shop_name'],
                            style: TextStyle(fontSize: 16.0),
                          ),
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
                            _buildInvoiceContentCompressed(document['items']),
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
                                      total.toString(),
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Center(
                                child: RaisedButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(
                                          color: Colors.orangeAccent)),
                                  onPressed: () {},
                                  color: Colors.orangeAccent,
                                  textColor: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    child: Text(
                                      "Mail Invoice",
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
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
                          'read': false,
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

  _showModalEditUserData(String dataType, String oldData) async {
    _dataController.text = oldData;
    String newData = "";
    String result = await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateSheet) =>
                AlertDialog(
                  title: Text('Change your $dataType'),
                  content: TextField(
                    controller: _dataController,
                    cursorColor: Theme.of(context).accentColor,
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(
                        'Save',
                        style: TextStyle(color: Theme.of(context).accentColor),
                      ),
                      onPressed: () async {
                        if (_dataController.text != oldData) {
                          // Data changed
                          newData = _dataController.text;
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Theme.of(context).accentColor),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )));
    return newData;
  }

  showRatingDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: true, // set to false if you want to force a rating
        builder: (context) {
          return RatingDialog(
            icon: const FlutterLogo(size: 100, colors: Colors.red),
            title: "Rate the App",
            description: "Tap a star to set your rating.",
            submitButton: "SUBMIT",
            alternativeButton: "Contact us instead?",
            positiveComment: "We are glad to hear that.",
            negativeComment: "We're sad to hear that.",
            accentColor: Colors.red,
            onSubmitPressed: (int rating) {
              print("onSubmitPressed: rating = $rating");
              // TODO: open the app's page on Google Play / Apple App Store
            },
            onAlternativePressed: () {
              print("onAlternativePressed: do something");
              // TODO: maybe you want the user to contact you instead of rating a bad review
            },
          );
        });
  }

  Widget buildUserProfile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
                leading: SizedBox(
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(profilePicUrl),
                  ),
                ),
                title: Text(userData['name'],
                    style: TextStyle(
                        fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
                subtitle: Text(userEmail,
                    style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {},
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentList(
                          userData: userData,
                          title: "All Orders",
                          appointmentStatus: "None",
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                      leading: Icon(Icons.list),
                      title: Text("All My Orders",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentList(
                          userData: userData,
                          title: "Pending Orders",
                          appointmentStatus: "incomplete",
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text("Pending Orders",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentList(
                          userData: userData,
                          title: "Finished Orders",
                          appointmentStatus: "completed",
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                      leading: Icon(Icons.shopping_basket),
                      title: Text("Finished Orders",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
              ],
            )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Share.share(
                        'Check out QuickGrab to effectively maintain social distancing when buying items at shops.');
                  },
                  child: ListTile(
                      leading: Icon(Icons.mail),
                      title: Text("Invite Friends",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () async {
                    final Uri params = Uri(
                      scheme: 'mailto',
                      path: 'adityachakraborti14@gmail.com',
                    );
                    String url = params.toString();
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      print('Could not launch $url');
                    }
                  },
                  child: ListTile(
                      leading: Icon(Icons.headset_mic),
                      title: Text("Customer Support",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {
                    showRatingDialog(context);
                  },
                  child: ListTile(
                      leading: Icon(Icons.stars),
                      title: Text("Rate our app",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => CustomDialog(
                        title: "Suggestions",
                        description: "Type in your suggestions here.",
                        buttonText: "Okay",
                        hint: "Type in your suggestions here.",
                        formkey: suggestionformKey,
                        textController: suggestionTextController,
                      ),
                    );
                  },
                  child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text("Make a suggestion",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
              ],
            )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    googleSignIn.signOut();
                    FirebaseAuth.instance.signOut();
                  },
                  child: ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text("Logout",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget buildBody() {
    if (currentPage == 0) {
      return buildHomeUser();
    } else if (currentPage == 1) {
      return buildAppointmentsUser();
    } else if (currentPage == 2) {
      return buildAppointmentsDoneUser();
    } else {
      return buildUserProfile();
    }
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

  Widget notificationIcon(BuildContext context) {
    if (userLoaded) {
      return new StreamBuilder(
          stream: Firestore.instance
              .collection('notifications')
              .where('receiver_uid', isEqualTo: userData.documentID)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
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
            return new Badge(
              position: BadgePosition.topRight(right: 4, top: 4),
              badgeContent: SizedBox(height: 20),
              child: new IconButton(
                icon: Icon(Icons.notifications,
                    color: Theme.of(context).accentColor),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              NotificationsView(userData: userData)));
                },
              ),
            );
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

  List<Widget> returnActionButton() {
    if (currentPage == 0) {
      return <Widget>[
        notificationIcon(context),
        cartIcon(context),
        SizedBox(width: 10),
      ];
    } else if (currentPage == 1) {
      return <Widget>[
        cartIcon(context),
        SizedBox(width: 10),
      ];
    } else if (currentPage == 2) {
      return <Widget>[cartIcon(context)];
    } else {
      return <Widget>[
        notificationIcon(context),
        cartIcon(context),
        SizedBox(width: 10),
      ];
    }
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
          actions: returnActionButton()),
      body:
          userLoaded ? buildBody() : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: CubertoBottomBar(
        inactiveIconColor: Theme.of(context).accentColor,
        tabStyle: CubertoTabStyle.STYLE_FADED_BACKGROUND,
        // By default its CubertoTabStyle.STYLE_NORMAL
        selectedTab: currentPage,
        // By default its 0, Current page which is fetched when a tab is clickd, should be set here so as the change the tabs, and the same can be done if willing to programmatically change the tab.
        tabs: [
          TabData(
            iconData: Icons.home,
            title: "Nearby",
            tabColor: Theme.of(context).accentColor,
          ),
          TabData(
            iconData: Icons.av_timer,
            title: "Appointments",
            tabColor: Theme.of(context).accentColor,
          ),
          TabData(
            iconData: Icons.library_books,
            title: "Invoices",
            tabColor: Theme.of(context).accentColor,
          ),
          TabData(
            iconData: Icons.supervisor_account,
            title: "Profile",
            tabColor: Theme.of(context).accentColor,
          ),
        ],
        onTabChangedListener: (position, title, color) {
          setState(() {
            currentPage = position;
            currentTitle = title;
          });
        },
      ),
    );
  }
}
