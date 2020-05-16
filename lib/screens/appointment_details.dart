import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../fonts.dart';

class AppointmentDetails extends StatefulWidget {
  AppointmentDetails({Key key, this.appointmentData, this.timeSlots, this.shopScheduled,
  this.shopData})
      : super(key: key);

  final DocumentSnapshot appointmentData;
  final List<String> timeSlots;
  final List<DocumentSnapshot> shopScheduled;
  final DocumentSnapshot shopData;

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

  String selectedTimeSlot;

  DateTime selectedDate = DateTime.now();
  bool datePicked = false;

  List<String> remainingSlots;

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  Widget appointmentView(BuildContext context) {
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
          Divider(
            color: Colors.grey,
          ),
          confirmView(context)
        ]);
  }

  Widget singleItem(var items, int index) {
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

  // order invoice start


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

  List<String> getStartTimes(){
    List<String> startTimesAll = [];
    for(var i = 0; i < widget.timeSlots.length; i++){
      String startTime = widget.timeSlots[i].split('--')[0];
      startTimesAll.add(startTime);
    }
    return startTimesAll;
  }

  int countOccurrencesUsingWhereMethod(List<String> list, String element) {
    if (list == null || list.isEmpty) {
      return 0;
    }
    var foundElements = list.where((e) => e == element);
    return foundElements.length;
  }

  List<String> getLimits(){
    List<String> startTimes = [];
    for (var i=0; i<widget.shopScheduled.length; i++){
      startTimes.add(widget.shopScheduled[i].data['appointment_start']);
    }

    List<String> remaningSlots = [];
    List<String> allStartTimes = getStartTimes();

    for (var i = 0; i < allStartTimes.length; i++){
      if (startTimes.contains(allStartTimes[i])){
        remaningSlots.add(widget.timeSlots[i] + "-- Remaining Slots (" + (widget.shopData.data['limit'] - countOccurrencesUsingWhereMethod(startTimes, allStartTimes[i])).toString() + ")");
      } else {
        remaningSlots.add(widget.timeSlots[i] + "-- Remaining Slots (" + widget.shopData.data['limit'].toString() + ")");
      }
    }
    return remaningSlots;
  }

  Widget scheduledAppointments(DocumentSnapshot document, String total) {
    return Card(
      margin: EdgeInsets.all(10.0),
      elevation: 2,
      child: Container(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    "Name:",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    document['shopper_name'],
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
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
                        document['appointment_data'] != null
                            ? document['appointment_data']
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Item",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          ],
        ),
      ),
    );
  }

  Widget orderView() {
    String total = totalAmount(widget.appointmentData['items']);
    return Container(
        child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.485,
      child: SingleChildScrollView(
        child: scheduledAppointments(widget.appointmentData, total),
      ),
    ));
  }

  // order invoice end

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        print(selectedDate.toString());
        datePicked = true;
      });
  }

  Widget confirmView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListTile(
              onTap: () async {
                await _selectDate(context);
              },
              title: Text(
                "Select Date",
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: datePicked
                  ? Text(selectedDate.day.toString() +
                      "-" +
                      selectedDate.month.toString() +
                      "-" +
                      selectedDate.year.toString())
                  : Text("No date selected.")),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListTile(
            title: Text(
              "Select Time Slot",
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: DropdownButton<String>(
              hint: Text(
                "Select Time Slot",
                overflow: TextOverflow.ellipsis,
              ),
              value: selectedTimeSlot,
              items: remainingSlots.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (_) {
                valueDrop = _;
                setState(() {
                  selectedTimeSlot = _;
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
                if (selectedDate != null &&
                    startTimeController.text != null &&
                    endTimeController.text != null) {
                  String formattedDate =
                      "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
                  startTime = valueDrop.split('--')[0];
                  endTime = valueDrop.split('--')[1];
                  Firestore.instance
                      .collection('appointments')
                      .document(widget.appointmentData.documentID)
                      .updateData({
                    'appointment_start': startTime,
                    'appointment_end': endTime,
                    'appointment_date': formattedDate,
                    'appointment_status': 'scheduled'
                  }).then((value) async {
                    await Firestore.instance
                        .collection('appointments')
                        .document(widget.appointmentData.documentID)
                        .get()
                        .then((doc) async {
                      var title = "Apopintment scheduled";
                      var body = "Your appointment at " +
                          doc['shop_name'] +
                          " is scheduled";
                      await Firestore.instance.collection('notifications').add({
                        'sender_type': "shops",
                        'receiver_uid': doc['shopper_uid'],
                        'title': title,
                        'body': body,
                        'read': false,
                      });
                    });
                  });

                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                }
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
  void initState() {
    // TODO: implement initState
    remainingSlots = getLimits();
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
        body: SingleChildScrollView(child: appointmentView(context))
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
