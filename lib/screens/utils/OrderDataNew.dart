import 'package:app/fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:ticket_pass_package/ticket_pass.dart';
import 'package:app/screens/utils/custom_ticket_pass.dart';

class OrderDataNew extends StatefulWidget {
  final DocumentSnapshot document;
  final String total;
  final bool displayOTP;
  final bool isInvoice;
  final bool isExpanded;
  final bool isShop;

  OrderDataNew({Key key, this.document, this.total, this.displayOTP = false,
    this.isInvoice = false, this.isExpanded = true, this.isShop=false})
      : super(key: key);

  @override
  _OrderDataNewState createState() => _OrderDataNewState();
}

class _OrderDataNewState extends State<OrderDataNew> {
  int totalQty = 0;
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
                    Icon(Icons.reorder),
                    SizedBox(width: 10),
                    widget.isShop ?
                    Text(document.data['shopper_name'], style: TextStyle(color: Colors.black))
                    : Text(document.data['shop_name'], style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              widget.isShop ? SizedBox(width: 1)
              :
              widget.isInvoice ?
              InkWell(
                onTap: (){

                },
                  child: Chip(backgroundColor: Theme.of(context).accentColor,
                      label: Icon(Icons.mail, color: Colors.white))) :
              widget.displayOTP ?
              Chip(
                backgroundColor: Theme.of(context).accentColor,
                label: Text("OTP : " + document.data['otp'], style: TextStyle(color: Colors.white)),
              ) :
                  SizedBox(width: 1)
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

  Widget orderCardTicket(DocumentSnapshot document, String total) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TicketPass(
        alignment: Alignment.center,
        animationDuration: Duration(seconds: 1),
        expansionChild:
            SingleChildScrollView(child: orderCardTable(document, total)),
        expandedHeight: 500,
        expandIcon: CircleAvatar(
          maxRadius: 14,
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 20,
          ),
        ),
        expansionTitle: Text(
          'Order Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        separatorColor: Colors.black,
        separatorHeight: 1.0,
        color: Colors.white,
        curve: Curves.easeOut,
        titleColor: Colors.orangeAccent,
        shrinkIcon: CircleAvatar(
          maxRadius: 14,
          child: Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white,
            size: 20,
          ),
        ),
        ticketTitle: Text(
          'See Items',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        titleHeight: 45,
        width: 300,
        height: 200,
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 3,
        shouldExpand: true,
        child: Container(
          margin: EdgeInsets.all(10.0),
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
                          document['appointment_date'] != null
                              ? document['appointment_date']
                              : "Pending",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ],
                  ),
                  widget.displayOTP
                      ? Row(
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
                        )
                      : Container(),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: orderCardNew(widget.document, widget.total),
    );
  }
}
