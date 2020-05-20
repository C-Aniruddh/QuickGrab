import 'dart:async';
import 'package:app/screens/utils/OrderDataNew.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../fonts.dart';

class ShopCompletedOrders extends StatefulWidget {
  ShopCompletedOrders({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _ShopCompletedOrdersState createState() => _ShopCompletedOrdersState();
}

class _ShopCompletedOrdersState extends State<ShopCompletedOrders> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

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

  String totalAmount(var items){
    double total = 0;

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      if(item['available']){
        if (item['cost'] == "NA"){
          return "NA";
        }

        total = total +
            (int.parse(item['cost']) *
                int.parse(
                    item['quantity'].toString()));
      }
    }

    return total.toString();
  }


  Widget buildCompletedShop() {

    List<String> statusStrings = ['completed', 'cancelled'];

    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', whereIn: statusStrings)
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
                    child: Text("You have never accepted an appointment.", style: TextStyle(
                        fontFamily: AppFontFamilies.mainFont)),
                  );
                } else {
                  return new Container(
                    child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        DocumentSnapshot document = documents[index];
                        String total = totalAmount(document['items']);
                        return OrderDataNew(
                          document: document,
                          total: total,
                          isInvoice: false,
                          isExpanded: true,
                          isShop: true,
                          displayOTP: false,
                        );
                      },
                    ),
                  );
                }
            }
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(icon: Icon(Icons.close),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text("Completed Orders",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildCompletedShop()
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}