import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetails extends StatefulWidget {
  OrderDetails({Key key, this.orderData}) : super(key: key);
  final DocumentSnapshot orderData;

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  

  Widget buildBody() {
    // return buildAppointmentsDoneUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text("Order Details", style: TextStyle(color: Colors.black)),
        ),
      ),
      body: buildBody(),
    );
  }
}
