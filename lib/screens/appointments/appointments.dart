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
  Widget buildAppointments() {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: widget.appointmentStatus == "None"
            ? Firestore.instance
                .collection('appointments')
                .where('shopper_uid', isEqualTo: widget.userData['uid'])
                .snapshots()
            : Firestore.instance
                .collection('appointments')
                .where('appointment_status',
                    isEqualTo: widget.appointmentStatus)
                .where('shopper_uid', isEqualTo: widget.userData['uid'])
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
                          child: ListTile(
                            title: Text(
                              "22 May, " + document['shop_name'],
                              style: TextStyle(fontSize: 16.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(
                              Icons.shopping_basket,
                              color:
                                  document['appointment_status'] == "completed"
                                      ? Colors.grey
                                      : Colors.orangeAccent,
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () {},
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
          }
        },
      ),
    );
  }

  Widget buildBody() {
    return buildAppointments();
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
