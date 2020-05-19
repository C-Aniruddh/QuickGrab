import 'dart:async';
import 'package:app/screens/appointment_details.dart';
import 'package:app/screens/utils/OrderDataNew.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';

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

class ShopPendingOrders extends StatefulWidget {
  ShopPendingOrders({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _ShopPendingOrdersState createState() => _ShopPendingOrdersState();
}

class _ShopPendingOrdersState extends State<ShopPendingOrders> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool userLoaded = false;
  bool timeSlotsLoaded = false;
  GeoHasher gH = GeoHasher();

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();

  List<String> timeSlots;

  List<DocumentSnapshot> shopScheduled;

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

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
                        var title = "Appointment completed";
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

  String totalAmount(var items) {
    double total = 0;

    for (var i = 0; i < items.length; i++) {
      var item = items[i];

      if (item['cost'] == "NA") {
        return "NA";
      }

      total = total +
          (int.parse(item['cost']) * int.parse(item['quantity'].toString()));
    }

    return total.toString();
  }

  Widget buildAppDet(DocumentSnapshot document){
    String total = totalAmount(document['items']);
    return InkWell(
      onTap: (){
        if(shopScheduled == null){
          Firestore.instance.collection('appointments')
              .where('target_shop', isEqualTo: widget.userData.documentID)
              .where('appointment_status', isEqualTo: "scheduled")
              .getDocuments()
              .then((docs) => {
            shopScheduled = docs.documents
          });
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentDetails(appointmentData: document, timeSlots: timeSlots, shopScheduled: shopScheduled, shopData: widget.userData,)));
      },
      child: IgnorePointer(
        child: OrderDataNew(
          document: document,
          total: total,
          displayOTP: false,
          isInvoice: true,
          isExpanded: true,
          isShop: true,
        ),
      ),
    );
  }

  Widget buildAppointmentDetails(DocumentSnapshot document) {
    String startTime;
    String endTime;
    String valueDrop;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentDetails(appointmentData: document,)));
        },
        child: Card(
          margin: EdgeInsets.all(10.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: ExpansionTile(
                title: Text(
                  document['shopper_name'],
                  style: TextStyle(fontSize: 16.0),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ListTile(
                      title: Text("Select time slot"),
                      subtitle: DropdownButton<String>(
                        items: timeSlots.map((String value) {
                          return new DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                        onChanged: (_) {
                          valueDrop = _;
                          setState(() {
                            valueDrop = _;
                            startTimeController.text = valueDrop.split('--')[0];
                            endTimeController.text = valueDrop.split('--')[1];
                          });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Center(
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Colors.orangeAccent)),
                        onPressed: () {
                          startTime = valueDrop.split('--')[0];
                          endTime = valueDrop.split('--')[1];
                          Firestore.instance
                              .collection('appointments')
                              .document(document.documentID)
                              .updateData({
                            'appointment_start': startTime,
                            'appointment_end': endTime,
                            'appointment_status': 'scheduled'
                          }).then((value) async {
                            await Firestore.instance
                                .collection('appointments')
                                .document(document.documentID)
                                .get()
                                .then((doc) async {
                              var title = "Appointment scheduled";
                              var body = "Your appointment at " + doc['shop_name'] + " is scheduled";
                              await Firestore.instance.collection('notifications').add({
                                'sender_type': "shops",
                                'receiver_uid': doc['shopper_uid'],
                                'title': title,
                                'body': body,
                                'read': false,
                              });
                            });
                          });
                        },
                        color: Colors.orangeAccent,
                        textColor: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            "Confirm Appointment",
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPendingShop() {
    return Container(
        child: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('appointments')
          .where('appointment_status', isEqualTo: 'pending')
          .where('target_shop', isEqualTo: widget.userData['uid'])
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
                child: Text("You have no appointment requests.",
                    style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
              );
            } else {
              return new Container(
                  child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        DocumentSnapshot document = documents[index];
                        return buildAppDet(document);
                      }));
            }
        }
      },
    ));
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

  String getCity(String address) {
    List<String> elements = address.split(',');
    String city = elements[elements.length - 3];
    return city.trim();
  }

  getIntervals(String st, String et) {
    List<String> start = st.split(':');
    List<String> end = et.split(':');

    int startHour = int.parse(start[0]);
    int startMinute = int.parse(start[1]);
    int endHour = int.parse(end[0]);
    int endMinute = int.parse(end[1]);

    Jiffy startTime = Jiffy({"hour": startHour, "minute": startMinute});

    Jiffy endTime = Jiffy({"hour": endHour, "minute": endMinute});

    int currentHour = 0;
    int currentMinute = 0;

    List<String> slots = [];
    Jiffy previousTime = startTime;

    while (previousTime.isBefore(endTime)) {
      Jiffy tempTime = new Jiffy(previousTime);
      Jiffy newTime = Jiffy(tempTime.add(duration: Duration(minutes: 15)));
      currentHour = newTime.hour;
      currentMinute = newTime.minute;
      slots.add(previousTime.format("HH:mm") + "--" + newTime.format("HH:mm"));
      previousTime = newTime;
    }
    // print(slots);
    return slots;
  }

  updateTimeSlots() async {
    print(getCity(widget.userData['shop_address']));
    Firestore.instance
        .collection('cities')
        .where('city', isEqualTo: getCity(widget.userData['shop_address']))
        .getDocuments()
        .then((docs) async {
      if (docs.documents.isEmpty) {
        print("empty");
        String startTime = "04:00";
        String endTime = "21:00";
        timeSlots = getIntervals(startTime, endTime);
        setState(() {
          timeSlots = getIntervals(startTime, endTime);
        });
      } else {
        String startTime = docs.documents[0]['start_time'];
        String endTime = docs.documents[0]['end_time'];
        timeSlots = getIntervals(startTime, endTime);
        setState(() {
          timeSlots = getIntervals(startTime, endTime);
          timeSlotsLoaded = true;
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    Firestore.instance.collection('appointments')
        .where('target_shop', isEqualTo: widget.userData.documentID)
        .where('appointment_status', isEqualTo: "scheduled")
        .getDocuments()
        .then((docs) => {
        shopScheduled = docs.documents
    });
    updateTimeSlots();
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
        body: buildPendingShop()
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
