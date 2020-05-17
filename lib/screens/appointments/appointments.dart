import 'package:app/screens/utils/OrderDataNew.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppointmentList extends StatefulWidget {
  AppointmentList({Key key, this.userData, this.appointmentStatus, this.title})
      : super(key: key);
  final DocumentSnapshot userData;
  final String title;
  final String appointmentStatus;

  @override
  _AppointmentListState createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {

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

  Widget scheduledAppointments(DocumentSnapshot document, String total) {
    return OrderDataNew(
      document: document,
      total: total,
      isInvoice: false,
      isExpanded: true,
      isShop: false,
      displayOTP: true,
    );
  }


  Widget buildAppointmentsUser() {
    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: widget.appointmentStatus)
              .where('shopper_uid', isEqualTo: widget.userData.documentID)
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
                        String total = totalAmount(document['items']);
                        return scheduledAppointments(document, total);
                      },
                    ),
                  );
                }
            }
          },
        ));
  }
  Widget buildBody() {
    return buildAppointmentsUser();
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
          child: Text(widget.title, style: TextStyle(color: Colors.black)),
        ),
      ),
      body: buildBody(),
    );
  }
}
