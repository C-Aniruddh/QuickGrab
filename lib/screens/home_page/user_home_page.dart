import 'dart:async';
import 'package:app/fonts.dart';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/cart/cart_page.dart';
import 'package:app/screens/shop_page/shop_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';

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

  String token;

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController _dataController = TextEditingController();

  void setUserData(String uid) async {
    token = await FirebaseNotifications().setUpFirebase();
    await Firestore.instance
        .collection('users')
        .document(uid)
        .get()
        .then((data) {
      userData = data;
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
    Firestore.instance.collection('shops')
        .where('shop_name', isEqualTo: search).getDocuments()
        .then((documents) {
      result = documents.documents;
    });
    return result;
  }

  Widget buildHomeUser(){
    return SingleChildScrollView(
      child: Column(
        children: [
          addressView(),
          offersView(),
          Divider(),
          favoritesView(),
          Divider(),
          nearbyView()
        ]
      )
    );
  }

  Widget addressView(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(title: Text(userData['address'], style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
      )),
    );
  }

  Widget nearbyView(){
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Stores near you", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: buildNearbyGrid(),
          )
        ]
    );
  }

  Widget offersView(){
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Offers", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Card(
                    child: Container(
                        width: 160.0,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Laxmi Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                            ))
                    ),
                  ),
                  Card(
                    child: Container(
                        width: 160.0,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Pro Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                            ))
                    ),
                  ),

                  Card(
                    child: Container(
                        width: 160.0,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Man Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                            ))
                    ),
                  ),

                  Card(
                    child: Container(
                        width: 160.0,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Extra Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                            ))
                    ),
                  ),

                  Card(
                    child: Container(
                        width: 160.0,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Test Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                            ))
                    ),
                  ),
                ],),
            ),
          )]
    );
  }

  Widget favoritesView(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text("Favourites", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
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
                              child: Image(image: NetworkImage("https://i.imgur.com/HCw2Ho7.png"), height: 128, width: 128)),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Laxmi Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Container(
                width: 160.0,
                  child: Align(alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Laxmi Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                  ))
                ),
              ),
                Card(
                  child: Container(
                      width: 160.0,
                      child: Align(alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Pro Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                          ))
                  ),
                ),

                Card(
                  child: Container(
                      width: 160.0,
                      child: Align(alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Man Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                          ))
                  ),
                ),
                Card(
                  child: Container(
                      width: 160.0,
                      child: Align(alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Extra Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                          ))
                  ),
                ),
                Card(
                  child: Container(
                      width: 160.0,
                      child: Align(alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Test Stores", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                          ))
                  ),
                ),
              ],),
          ),
        )]
    );
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
            List<DocumentSnapshot> filterList = filterByDistance(snapshot.data.documents);
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
                    color: Colors.grey[900],
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

  Widget buildAppointmentsUser() {
    List<String> status = ['pending', 'scheduled'];
    return Container(
        child: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('appointments')
          .where('appointment_status', whereIn: status)
          .where('shopper_uid', isEqualTo: userUID)
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
                        return Card(
                          margin: EdgeInsets.all(10.0),
                          elevation: 2,
                          child: Container(
                            child: new ListTile(
                              contentPadding: EdgeInsets.all(8),
                              onTap: () {
                                _showModalAppointmentDetails(document);

                                // Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
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
                              subtitle: Text(document['appointment_status']),
                              trailing: IconButton(
                                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                icon: Icon(Icons.info),
                                onPressed: () {
                                  print("Open");
                                  _showModalAppointmentDetails(document);
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
                        return Card(
                          margin: EdgeInsets.all(10.0),
                          elevation: 2,
                          child: Container(
                            child: new ListTile(
                              contentPadding: EdgeInsets.all(8),
                              onTap: () {
                                _showModalAppointmentDetails(document);
                                //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
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
                              subtitle: Text(document['appointment_status']),
                              trailing: IconButton(
                                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                icon: Icon(Icons.info),
                                onPressed: () {
                                  print("Open");
                                  _showModalAppointmentDetails(document);
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
              trailing: IconButton(icon: Icon(Icons.edit),
              onPressed: (){
              },)
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {},
                  child: ListTile(
                      leading: Icon(Icons.list),
                      title: Text("All My Orders",
                          style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text("Pending Orders",
                          style:
                          TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                ),
                Divider(),
                InkWell(
                  onTap: () {},
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
                      onTap: () {},
                      child: ListTile(
                          leading: Icon(Icons.mail),
                          title: Text("Invite Friends",
                              style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                          trailing: Icon(Icons.arrow_forward_ios)),
                    ),
                    Divider(),
                    InkWell(
                      onTap: () {},
                      child: ListTile(
                          leading: Icon(Icons.headset_mic),
                          title: Text("Customer Support",
                              style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                          trailing: Icon(Icons.arrow_forward_ios)),
                    ),
                    Divider(),
                    InkWell(
                      onTap: () {},
                      child: ListTile(
                          leading: Icon(Icons.stars),
                          title: Text("Rate our app",
                              style:
                              TextStyle(fontFamily: AppFontFamilies.mainFont)),
                          trailing: Icon(Icons.arrow_forward_ios)),
                    ),
                    Divider(),
                    InkWell(
                      onTap: () {},
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

  List<Widget> returnActionButton() {
    if (currentPage == 0) {
      return <Widget>[
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
          },
        )
      ];
    } else if (currentPage == 1) {
      return <Widget>[
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
          },
        )
      ];
    } else if (currentPage == 2) {
      return <Widget>[
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
          },
        )
      ];
    } else {
      return <Widget>[
        IconButton(
          icon: Icon(Icons.notifications, color: Theme.of(context).accentColor),
          onPressed: () async {},
        ),
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
          },
        )
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
