import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../fonts.dart';

class VerifyShop extends StatefulWidget {
  VerifyShop({Key key, this.shopData}) : super(key: key);
  final DocumentSnapshot shopData;

  @override
  _VerifyShopState createState() => _VerifyShopState();
}

class _VerifyShopState extends State<VerifyShop> {
  File _image;
  final _formKey = GlobalKey<FormState>();
  String _url;

  TextEditingController gstController = new TextEditingController();
  TextEditingController vatController = new TextEditingController();

  Future getGalleryImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 60);
    setState(() {
      _image = image;
    });
  }

  Future getCameraImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 60);
    setState(() {
      _image = image;
    });
  }

  Future uploadFile(File file, String filename) async {
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child("images/$filename");
    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
    return url;
  }

  _showUploadChoiceDialog(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select image from...',
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Gallery',
                    ),
                    leading: Icon(Icons.photo_size_select_actual),
                    onTap: () async {
                      await getGalleryImage();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text(
                      'Camera',
                    ),
                    leading: Icon(Icons.camera_alt),
                    onTap: () async {
                      await getCameraImage();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget customTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 56.0,
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
            new Container(
              child: new IconButton(icon: Icon(iconData), onPressed: null),
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
                      return 'This field cannot be empty';
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

  Widget _previewImage() {
    if (_image != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 4,
              blurRadius: 5,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.file(_image),
        ),
      );
    } else {
      return Container(
        width: 275.0,
        height: 275.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 4,
              blurRadius: 5,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Icon(
            Icons.add_a_photo,
            size: 128.0,
          ),
        ),
      );
    }
  }

  _showErrorDialog(BuildContext parentContext, String text) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              text,
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Okay"),
              )
            ],
          );
        });
  }

  showAlertDialog(BuildContext context, String title, String content) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title:
          Text(title, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
      content:
          Text(content, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              "Verify your shop by uploading a picture of your documents or by filling the information fields with your GST or VAT number.",
              maxLines: 4,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Not sure what to do?",
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.orangeAccent)),
                  onPressed: () async {
                    launch("tel://+919930533637");
                  },
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          SizedBox(
            height: 4.0,
          ),
          Container(
            height: 225.0,
            width: 225.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Center(
                child: _previewImage(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.orangeAccent)),
                onPressed: () async {
                  _showUploadChoiceDialog(context);
                },
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _image == null
                        ? "Add a picture"
                        : "Retake picture".toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new SizedBox(
                  height: 10.0,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: new Center(
                    child: new Container(
                      margin:
                          new EdgeInsetsDirectional.only(start: 1.0, end: 1.0),
                      height: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text("OR"),
                new SizedBox(
                  height: 10.0,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: new Center(
                    child: new Container(
                      margin:
                          new EdgeInsetsDirectional.only(start: 1.0, end: 1.0),
                      height: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          customTextField(
            Icons.shop,
            "GST Number",
            gstController,
          ),
          customTextField(
            Icons.person,
            "VAT Number",
            vatController,
          ),
          SizedBox(
            height: 8.0,
          ),
          Divider(
            color: Colors.grey,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(
                    color: Theme.of(context).accentColor,
                  ),
                ),
                onPressed: () async {
                  if (_image != null) {
                    // only image needed
                    _url = await uploadFile(_image, widget.shopData['uid']);
                    Firestore.instance
                        .collection('verification_requests')
                        .document(widget.shopData.documentID)
                        .setData({
                      'image': _url,
                      'gst': gstController.text,
                      'vat': vatController.text
                    });
                    showAlertDialog(context, "Verification Request Received",
                        "Please wait a few hours for verification or contact us if urgent.");
                  } else if (gstController.text.isEmpty) {
                    if (vatController.text.isEmpty) {
                      _showErrorDialog(context,
                          "If no image is uploaded, then at least GST or VAT must be provided");
                    } else {
                      Firestore.instance
                          .collection('verification_requests')
                          .document(widget.shopData.documentID)
                          .setData({
                        'image': _url,
                        'gst': gstController.text,
                        'vat': vatController.text
                      });
                      showAlertDialog(context, "Verification Request Received",
                          "Please wait a few hours for verification or contact us if urgent.");
                    }
                    // supply vat
                  } else if (vatController.text.isEmpty) {
                    if (gstController.text.isEmpty) {
                      _showErrorDialog(context,
                          "If no image is uploaded, then at least GST or VAT must be provided");
                    } else {
                      Firestore.instance
                          .collection('verification_requests')
                          .document(widget.shopData.documentID)
                          .setData({
                        'image': _url,
                        'gst': gstController.text,
                        'vat': vatController.text
                      });
                      showAlertDialog(context, "Verification Request Received",
                          "Please wait a few hours for verification or contact us if urgent.");
                    }
                    // supply gst
                  } else {
                    Firestore.instance
                        .collection('verification_requests')
                        .document(widget.shopData.documentID)
                        .setData({
                      'image': _url,
                      'gst': gstController.text,
                      'vat': vatController.text
                    });
                    showAlertDialog(context, "Verification Request Received",
                        "Please wait a few hours for verification or contact us if urgent.");
                  }
                },
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Submit".toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            child: Text(
              "Verify Shop",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: buildBody(),
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
