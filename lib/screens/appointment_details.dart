import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../fonts.dart';

class AppointmentDetails extends StatefulWidget {
  AppointmentDetails({Key key, this.appointmentData, this.timeSlots}) : super(key: key);

  final DocumentSnapshot appointmentData;
  final List<String> timeSlots;

  @override
  _AppointmentDetailsState createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();

  String startTime;
  String endTime;
  String valueDrop;



  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  Widget appointmentView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("User requires",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          orderView(),
          confirmView()
        ]);
  }

  Widget singleItem(var items, int index){
    var item = items[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
              leading: SizedBox(
                child: CircleAvatar(
                  backgroundImage: NetworkImage(item['product']['img_url']),
                ),
              ),
              title: Text(item['product']['item_name'],
                  style: TextStyle(
                      fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
              subtitle: Text(item['product']['item_price'],
                  style: TextStyle(fontFamily: AppFontFamilies.mainFont)),

          ),
        ),
      ),
    );
  }

  Widget orderView() {
    var items = widget.appointmentData.data['items'];
    return Container(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return singleItem(items, index);
              }),
        ));
  }

  Widget confirmView(){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListTile(
            title: Text("Select time slot"),
            subtitle: DropdownButton<String>(
              items: widget.timeSlots.map((String value) {
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
                print(valueDrop);
                startTime = valueDrop.split('--')[0];
                endTime = valueDrop.split('--')[1];
                Firestore.instance
                    .collection('appointments')
                    .document(widget.appointmentData.documentID)
                    .updateData({
                  'appointment_start': startTime,
                  'appointment_end': endTime,
                  'appointment_status': 'scheduled'
                }).then((value) async {
                  await Firestore.instance
                      .collection('appointments')
                      .document(widget.appointmentData.documentID)
                      .get()
                      .then((doc) async {
                    var title = "Apopintment scheduled";
                    var body = "Your appointment at " + doc['shop_name'] + " is scheduled";
                    await Firestore.instance.collection('notifications').add({
                      'sender_type': "shops",
                      'receiver_uid': doc['shopper_uid'],
                      'title': title,
                      'body': body,
                    });
                  });
                });

                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    );
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
      body: appointmentView()
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}