import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class TimePickerDialog extends StatefulWidget {
  @override
  State createState() => new _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  DateTime _dateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  Widget buildPicker() {
    return new TimePickerSpinner(
      is24HourMode: false,
      spacing: 40,
      minutesInterval: 15,
      onTimeChange: (time) {
        setState(() {
          _dateTime = time;
        });
      },
    );
  }

  Widget buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Theme.of(context).accentColor,
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Theme.of(context).accentColor,
            child: Text(
              "Select",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              int hour = _dateTime.hour;
              int min = _dateTime.minute;
              List hourMin = [hour, min];
              Navigator.pop(context, hourMin);
            },
          ),
        ),
      ],
    );
  }

  Widget buildBody() {
    return Column(
      children: <Widget>[
        buildPicker(),
        buildButtons(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          new Text("Select Time"),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      children: <Widget>[
        buildBody(),
      ],
    );
  }
}
