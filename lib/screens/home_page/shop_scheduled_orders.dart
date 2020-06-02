import 'dart:async';
import 'package:app/screens/utils/order_data_scheduled.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grouped_list/grouped_list.dart';

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
                    style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
              );
            } else {
              return new Container(
                child: GroupedListView(
                  useStickyGroupSeparators: false,
                  elements: documents,
                  groupBy: (element) => element['appointment_start'],
                  groupSeparatorBuilder: (dynamic groupByValue) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          Text("Appointments scheduled at " + '$groupByValue'),
                    );
                  },
                  itemBuilder: (context, element) {
                    DocumentSnapshot document = element;
                    String total = totalAmount(document['items']);
                    return OrderDataScheduled(
                      document: document,
                      total: total,
                      isInvoice: false,
                      isExpanded: false,
                      displayOTP: true,
                      isShop: true,
                      items: document['items'],
                    );
                  },
                  order: GroupedListOrder.ASC,
                ),
                /*ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        DocumentSnapshot document = documents[index];
                        String total = totalAmount(document['items']);
                        return OrderDataScheduled(
                          document: document,
                          total: total,
                          isInvoice: false,
                          isExpanded: false,
                          displayOTP: false,
                          isShop: true,
                        );
                      },
                    )*/
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
                          }))
              ;
              */
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
          leading: IconButton(
            icon: Icon(Icons.close),
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
