import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuggestionsDialog extends StatefulWidget {
  SuggestionsDialog({
    Key key,
    this.userData,
  }) : super(key: key);
  final DocumentSnapshot userData;

  @override
  _SuggestionsDialogState createState() => _SuggestionsDialogState();
}

class _SuggestionsDialogState extends State<SuggestionsDialog> {
  bool _isSubmitted = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController suggestionController = new TextEditingController();

  Widget customLargeTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 128.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * .85,
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
            new Container(
              child: new IconButton(icon: Icon(iconData), onPressed: null),
            ),
            new Flexible(
              child: new TextFormField(
                maxLines: 4,
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

  Widget buildButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(
              color: Theme.of(context).accentColor,
            ),
          ),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              Firestore.instance.collection('suggestions').add({
                "user_uid": widget.userData['uid'],
                "user_name": widget.userData['name'],
                "user_number": widget.userData['phone_number'],
                "user_address": widget.userData['address'],
                "suggestion": suggestionController.text,
              }).then((result) async {
                setState(() {
                  _isSubmitted = true;
                });
                await Future.delayed(const Duration(milliseconds: 1000), () {
                  Navigator.pop(context);
                });
              }).catchError((err) => print(err));
            }
          },
          color: Theme.of(context).accentColor,
          textColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Submit",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget submittedText() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Your suggestion has been sent.\nThank your for your input.",
        maxLines: 3,
      ),
    );
  }

  Widget buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _isSubmitted
              ? submittedText()
              : customLargeTextField(
                  Icons.description,
                  "Add your suggestions here",
                  suggestionController,
                ),
          _isSubmitted ? Container(
            height: 20.0,
          ) : buildButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            new Text("Suggestions"),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      children: <Widget>[
        buildBody(),
      ],
    );
  }
}
