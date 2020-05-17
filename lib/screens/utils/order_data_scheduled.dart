import 'package:app/fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:ticket_pass_package/ticket_pass.dart';
import 'package:app/screens/utils/custom_ticket_pass.dart';

class OrderDataScheduled extends StatefulWidget {
  final DocumentSnapshot document;
  final String total;
  final bool displayOTP;
  final bool isInvoice;
  final bool isExpanded;
  final bool isShop;


  OrderDataScheduled({Key key, this.document, this.total, this.displayOTP = false,
    this.isInvoice = false, this.isExpanded = true, this.isShop=false})
      : super(key: key);

  @override
  _OrderDataScheduledState createState() => _OrderDataScheduledState();
}

class _OrderDataScheduledState extends State<OrderDataScheduled> {
  int totalQty = 0;
  TextEditingController otpController = new TextEditingController();

  rowContent(invoiceData, total) {
    List<DataRow> rows = [];

    for (dynamic content in invoiceData) {
      rows.add(
        DataRow(
          cells: [
            DataCell(
              Container(
                width: MediaQuery.of(context).size.width * 0.25,
                child: Text(
                  content['product']['item_name'].toString(),
                  style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                child: Text(
                  content['quantity'].toString(),
                  style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                content['cost'].toString(),
                style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
      totalQty = totalQty + int.parse(content['quantity'].toString());
    }
    rows.add(
      DataRow(
        cells: [
          DataCell(
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              child: Text(
                "Total",
                style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              totalQty.toString(),
              style: TextStyle(
                fontFamily: AppFontFamilies.mainFont,
                color: Colors.black87,
              ),
            ),
          ),
          DataCell(
            Text(
              total.toString(),
              style: TextStyle(
                fontFamily: AppFontFamilies.mainFont,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
    return rows;
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


  String titleString(String s) => s[0].toUpperCase() + s.substring(1);

  Widget orderCardNew(DocumentSnapshot document, String total) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Row(
                  children: [
                    Icon(Icons.account_circle),
                    SizedBox(width: 10),
                    widget.isShop ?
                    Text(document.data['shopper_name'], style: TextStyle(color: Colors.black))
                    : Text(document.data['shop_name'], style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),

          initiallyExpanded: widget.isExpanded,
          children: [
            Divider(),
            widget.isInvoice ?
            SizedBox(height: 1)
            : Padding(
              padding: const EdgeInsets.fromLTRB(32, 4, 16, 0),
              child: Table(
                children: [
                  TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info),
                                SizedBox(width: 10,),
                                Text(titleString(document.data['appointment_status']), style: TextStyle(color: Colors.black)),
                              ]
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment),
                                SizedBox(width: 10,),
                                Text(total, style: TextStyle(color: Colors.black))
                              ]
                          ),
                        )
                      ]
                  ),
                  TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm),
                                SizedBox(width: 10,),
                                document.data['appointment_status'] == "pending" ?
                                Text("Waiting for shop", style: TextStyle(color: Colors.black))
                                    : Text(document.data['appointment_start'] + " - " + document.data['appointment_end'], style: TextStyle(color: Colors.black)),
                              ]
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today),
                                SizedBox(width: 10,),
                                document.data['appointment_status'] == "pending" ?
                                Text("Waiting for shop", style: TextStyle(color: Colors.black))
                                    : Text(document.data['appointment_date'], style: TextStyle(color: Colors.black)),
                              ]
                          ),
                        ),

                      ]
                  ),
                ],
              ),
            ),
            widget.isInvoice ? SizedBox(height: 1) :
            Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 16, 0),
                child: Text("Order Items"),
              ),
            ),
            orderCardTable(document, total),
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
        )
      ),
    );
  }

  Widget orderCardTable(DocumentSnapshot document, String total) {
    return DataTable(
      dividerThickness: 0.0,
      columns: [
        DataColumn(
          label: Text(
            "Item",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: false,
        ),
        DataColumn(
          label: Text(
            "Quantity",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            "Price",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: false,
        ),
      ],
      rows: rowContent(document['items'], total),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: orderCardNew(widget.document, widget.total),
    );
  }
}