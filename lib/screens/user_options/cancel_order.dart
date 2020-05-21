import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CancelReason extends StatefulWidget {

  DocumentSnapshot appointmentDetails;

  CancelReason(this.appointmentDetails);
  @override
  State createState() => new CancelReasonState();
}

class CancelReasonState extends State<CancelReason> {
  int selectedRadioTile;
  bool other = false;
  String reason = "";
  final _formKey = GlobalKey<FormState>();
  TextEditingController reasonController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedRadioTile = 0;
  }

  setSelectedRadioTile(int val, String reasonString) {
    setState(() {
      selectedRadioTile = val;
      reason = reasonString;
    });
  }

  Widget customTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 48.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * .88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 1.0,
              // has the effect of softening the shadow
              spreadRadius: 0.0,
              // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                0.0, // vertical, move down 10
              ),
            )
          ],
        ),
        child: new Row(
          children: <Widget>[
            SizedBox(
              width: 4.0,
            ),
            new Flexible(
              child: new TextFormField(
                enabled: enabled,
                keyboardType: keyType,
                decoration: new InputDecoration.collapsed(
                  hintText: hint,
                ),
                controller: textEditingController,
                validator: (value) {
                  if (validate) {
                    if (value.isEmpty) {
                      return "This field cannot be empty.";
                    } else {
                      return null;
                    }
                  } else {
                    return null;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return new SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: new Text("Specify Reason"),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              RadioListTile(
                value: 1,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setSelectedRadioTile(val, "Items Not Available");
                },
                title: Text("Items Not Available"),
              ),
              RadioListTile(
                value: 2,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setSelectedRadioTile(val, "Shop Closing Early");
                },
                title: Text("Shop Closing Early"),
              ),
              RadioListTile(
                value: 3,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setState(() {
                    other = true;
                  });
                  setSelectedRadioTile(val, "");
                },
                title: Text("Other"),
              ),
              selectedRadioTile == 3
                  ? Form(
                      key: _formKey,
                      child: customTextField(
                        Icons.view_headline,
                        "Reason for cancellation...",
                        reasonController,
                        validate: other ? true : false,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        Container(
          color: Colors.orange,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                color: Colors.orange,
                child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Don't Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              Container(
                color: selectedRadioTile == 0 ? Colors.grey : Colors.orange,
                child: FlatButton(
                  onPressed: selectedRadioTile == 0
                      ? null
                      : () {
                          if (selectedRadioTile == 1 || selectedRadioTile == 2) {
                            // Items Not Available
                            Firestore.instance.collection('appointments')
                                .document(widget.appointmentDetails.documentID)
                                .updateData({'appointment_status': 'cancelled',
                                'reason': reason});

                            String body = 'Your appointment at ' + widget.appointmentDetails.data['shop_name'] + ' has been cancelled.';
                            String title = 'Appointment cancelled';
                            Firestore.instance.collection('notifications')
                              .add({
                              'body': body,
                              'title': title,
                              'receiver_uid': widget.appointmentDetails.data['shopper_uid'],
                              'sender_type': 'shops',
                              'read': false,
                              'timestamp': DateTime.now()
                            });

                            Navigator.pop(context);
                          } else if (selectedRadioTile == 3) {
                            // Other selected
                            if (_formKey.currentState.validate()) {
                              reason = reasonController.text;
                              Firestore.instance.collection('appointments')
                                  .document(widget.appointmentDetails.documentID)
                                  .updateData({'appointment_status': 'cancelled',
                                'reason': reason});

                              String body = 'Your appointment at ' + widget.appointmentDetails.data['shop_name'] + ' has been cancelled.';
                              String title = 'Appointment cancelled';
                              Firestore.instance.collection('notifications')
                                  .add({
                                'body': body,
                                'title': title,
                                'receiver_uid': widget.appointmentDetails.data['shopper_uid'],
                                'sender_type': 'shops',
                                'read': false,
                                'timestamp': DateTime.now()
                              });

                              Navigator.pop(context);
                            }
                          }
                        },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




class CancelUserReason extends StatefulWidget {
  @override
  State createState() => new CancelUserReasonState();
}

class CancelUserReasonState extends State<CancelUserReason> {
  int selectedRadioTile;
  bool other = false;
  String reason = "";
  final _formKey = GlobalKey<FormState>();
  TextEditingController reasonController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedRadioTile = 0;
  }

  setSelectedRadioTile(int val, String reasonString) {
    setState(() {
      selectedRadioTile = val;
      reason = reasonString;
    });
  }

  Widget customTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 48.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * .88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 1.0,
              // has the effect of softening the shadow
              spreadRadius: 0.0,
              // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                0.0, // vertical, move down 10
              ),
            )
          ],
        ),
        child: new Row(
          children: <Widget>[
            SizedBox(
              width: 4.0,
            ),
            new Flexible(
              child: new TextFormField(
                enabled: enabled,
                keyboardType: keyType,
                decoration: new InputDecoration.collapsed(
                  hintText: hint,
                ),
                controller: textEditingController,
                validator: (value) {
                  if (validate) {
                    if (value.isEmpty) {
                      return "This field cannot be empty.";
                    } else {
                      return null;
                    }
                  } else {
                    return null;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return new SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: new Text("Cancel Order"),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              RadioListTile(
                value: 1,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setSelectedRadioTile(val, "Items Not Available");
                },
                title: Text("Inconvinient Slot"),
              ),
              RadioListTile(
                value: 2,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setSelectedRadioTile(val, "Shop Closing Early");
                },
                title: Text("Incorrect Items"),
              ),
              RadioListTile(
                value: 3,
                groupValue: selectedRadioTile,
                onChanged: (val) {
                  setState(() {
                    other = true;
                  });
                  setSelectedRadioTile(val, "");
                },
                title: Text("Other"),
              ),
              selectedRadioTile == 3
                  ? Form(
                      key: _formKey,
                      child: customTextField(
                        Icons.view_headline,
                        "Reason for cancellation...",
                        reasonController,
                        validate: other ? true : false,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        Container(
          color: Colors.orange,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                color: Colors.orange,
                child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Don't Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              Container(
                color: selectedRadioTile == 0 ? Colors.grey : Colors.orange,
                child: FlatButton(
                  onPressed: selectedRadioTile == 0
                      ? null
                      : () {
                          if (selectedRadioTile == 1) {
                            // Items Not Available
                            // TODO: send data
                          } else if (selectedRadioTile == 2) {
                            // Shop Closing Early
                            // TODO: send data
                          } else if (selectedRadioTile == 3) {
                            // Other selected
                            if (_formKey.currentState.validate()) {
                              reason = reasonController.text;
                              // TODO: send data
                            }
                          }
                        },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
