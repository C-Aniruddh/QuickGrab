import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../fonts.dart';

class ShopScheduledOrders extends StatefulWidget {
  ShopScheduledOrders({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _ShopScheduledOrdersState createState() => _ShopScheduledOrdersState();
}

class _ShopScheduledOrdersState extends State<ShopScheduledOrders> {

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
                      TextField(
                        obscureText: true,
                        controller: otpController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'OTP',
                        ),
                      )
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
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  String totalAmount(var items){
    double total = 0;

    for (var i = 0; i < items.length; i++) {
      var item = items[i];

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


  Widget buildHomeShop_old() {
    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: 'scheduled')
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
                    child: Text("You have no scheduled appointments.",
                      style: TextStyle(
                      fontFamily: AppFontFamilies.mainFont)),
                  );
                } else {
                  return new Container(
                    child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        DocumentSnapshot document = documents[index];
                        String total = totalAmount(document['items']);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            margin: EdgeInsets.all(10.0),
                            elevation: 2,
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ExpansionTile(
                                  leading: Icon(Icons.account_circle),
                                  title: Text(
                                    document['shopper_name'] ,
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Padding(
                                              padding:
                                              EdgeInsets.fromLTRB(16, 16, 16, 8),
                                              child: Text(
                                                "Date:",
                                                style: TextStyle(fontSize: 16.0),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                              EdgeInsets.fromLTRB(16, 16, 16, 8),
                                              child: Text(
                                                document['appointment_date'] != null
                                                    ? document['appointment_date']
                                                    : "Pending",
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
                                          onPressed: () {
                                            print("Open");
                                            _showCompleteDialog(context,
                                                document.documentID, document['otp']);
                                          },
                                          color: Colors.orangeAccent,
                                          textColor: Colors.white,
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                            child: Text(
                                              "Complete Order",
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
                        );
                      },
                    ),
                  );

                  /* Container(
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
                                    _showCompleteDialog(context,
                                        document.documentID, document['otp']);
                                    //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                                  },
                                  leading: Container(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: CircleAvatar(
                                        backgroundColor:
                                        Theme.of(context).accentColor,
                                        child: Text(document['shopper_name'][0]
                                            .toString()
                                            .toUpperCase()),
                                      )),
                                  title: Text(document['shopper_name']),
                                  subtitle: Text(document['appointment_status']),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    icon: Icon(Icons.check),
                                    onPressed: () {
                                      print("Open");
                                      _showCompleteDialog(context,
                                          document.documentID, document['otp']);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }))*/;
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
          child: Text("Scheduled Orders",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildHomeShop_old()
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}