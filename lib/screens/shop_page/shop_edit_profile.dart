import 'dart:io';

import 'package:app/screens/utils/timePickerDialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class EditShopProfile extends StatefulWidget {
  EditShopProfile({Key key, this.shopData}) : super(key: key);
  final DocumentSnapshot shopData;
  @override
  _EditShopProfileState createState() => _EditShopProfileState();
}

class _EditShopProfileState extends State<EditShopProfile> {
  File _image;
  File croppedImage;
  final _formKey = GlobalKey<FormState>();
  String _url;

  TextEditingController shopNameController = new TextEditingController();
  TextEditingController shopContactController = new TextEditingController();
  TextEditingController shopNumberController = new TextEditingController();

  String openingTime;
  String closingTime;

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

  Future<Null> _cropImage(File imageFile) async {
    croppedImage = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.ratio4x3,
      ],
      maxWidth: 1024,
      maxHeight: 1024,
    );
    setState(() {
      this._image = croppedImage;
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

  _showSelectTimeDialog(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(16.0),
            ),
            title: Text(
              'Please select both opening and closing timings',
              textAlign: TextAlign.center,
            ),
            actions: [
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Okay",
                    style: TextStyle(fontSize: 16.0),
                  ))
            ],
          );
        });
  }

  buildTimeOpening(String hourValue, String minuteValue) {
    String am_pm = "AM";
    int hour;
    String hr;

    if (hourValue != "" && minuteValue != "") {
      hour = int.parse(hourValue);
      if (hour > 12) {
        am_pm = "PM";
        hour = hour - 12;
      }
      if (hour == 12) {
        am_pm = "PM";
      }
      if (hour == 0 && am_pm == "AM") {
        hour = 12;
      }
      if (hour < 10) {
        hr = "0" + hour.toString();
      } else {
        hr = hour.toString();
      }
    }

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
              spreadRadius: 0.0,
              offset: Offset(
                0.0,
                0.0,
              ),
            )
          ],
        ),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    "Opening",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    hourValue == ""
                        ? "Not Set"
                        : hr + " : " + minuteValue + " " + am_pm,
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Center(
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side:
                              BorderSide(color: Theme.of(context).accentColor)),
                      onPressed: () async {
                        var data = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          child: TimePickerDialog(),
                        );
                        if (data != null) {
                          if (data[0] < 10) {
                            if (data[1] == 0) {
                              setState(() {
                                openingTime = "0" +
                                    data[0].toString() +
                                    ":" +
                                    data[1].toString() +
                                    "0";
                              });
                            } else {
                              setState(() {
                                openingTime = "0" +
                                    data[0].toString() +
                                    ":" +
                                    data[1].toString();
                              });
                            }
                          } else {
                            if (data[1] == 0) {
                              setState(() {
                                openingTime = data[0].toString() +
                                    ":" +
                                    data[1].toString() +
                                    "0";
                              });
                            } else {
                              setState(() {
                                openingTime = data[0].toString() +
                                    ":" +
                                    data[1].toString();
                              });
                            }
                          }
                        }
                      },
                      color: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Set Time",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  buildTimeClosing(String hourValue, String minuteValue) {
    String am_pm = "AM";
    int hour;
    String hr;

    if (hourValue != "" && minuteValue != "") {
      hour = int.parse(hourValue);
      if (hour > 12) {
        am_pm = "PM";
        hour = hour - 12;
      }
      if (hour == 12) {
        am_pm = "PM";
      }
      if (hour == 0 && am_pm == "AM") {
        hour = 12;
      }
      if (hour < 10) {
        hr = "0" + hour.toString();
      } else {
        hr = hour.toString();
      }
    }

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
              spreadRadius: 0.0,
              offset: Offset(
                0.0,
                0.0,
              ),
            )
          ],
        ),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    "Closing",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    hourValue == ""
                        ? "Not Set"
                        : hr.toString() + " : " + minuteValue + " " + am_pm,
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Center(
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side:
                              BorderSide(color: Theme.of(context).accentColor)),
                      onPressed: () async {
                        var data = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          child: TimePickerDialog(),
                        );
                        if (data != null) {
                          if (data[0] < 10) {
                            if (data[1] == 0) {
                              setState(() {
                                closingTime = "0" +
                                    data[0].toString() +
                                    ":" +
                                    data[1].toString() +
                                    "0";
                              });
                            } else {
                              setState(() {
                                closingTime = "0" +
                                    data[0].toString() +
                                    ":" +
                                    data[1].toString();
                              });
                            }
                          } else {
                            if (data[1] == 0) {
                              setState(() {
                                closingTime = data[0].toString() +
                                    ":" +
                                    data[1].toString() +
                                    "0";
                              });
                            } else {
                              setState(() {
                                closingTime = data[0].toString() +
                                    ":" +
                                    data[1].toString();
                              });
                            }
                          }
                        }
                      },
                      color: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Set Time",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
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
                      await _cropImage(_image);
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
                      await _cropImage(_image);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        });
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
      return InkWell(
        onTap: () async {
          _showUploadChoiceDialog(context);
        },
        child: Container(
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
            child: Image.network(widget.shopData['shop_image']),
          ),
        ),
      );
    }
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

  _showLoadingDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            content: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: Text(text),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            height: 275.0,
            width: 275.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Center(
                child: _previewImage(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Theme.of(context).accentColor)),
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
          Divider(
            color: Colors.black45,
          ),
          SizedBox(
            height: 16.0,
          ),
          customTextField(
            Icons.shop,
            "Shop Name",
            shopNameController,
          ),
          customTextField(
            Icons.person,
            "Shop Contact Name",
            shopContactController,
          ),
          customTextField(
            Icons.phone,
            "Shop Contact Number",
            shopNumberController,
            keyType: TextInputType.number,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48.0, 16.0, 0.0, 0.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Set Shop Timings",
                style: TextStyle(fontSize: 15.0),
              ),
            ),
          ),
          openingTime != null
              ? buildTimeOpening(
                  openingTime.substring(0, 2), openingTime.substring(3))
              : buildTimeOpening("", ""),
          closingTime != null
              ? buildTimeClosing(
                  closingTime.substring(0, 2), closingTime.substring(3))
              : buildTimeClosing("", ""),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Theme.of(context).accentColor)),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _showLoadingDialog(context, "Submitting...");
                    if (_image != null) {
                      _url = await uploadFile(
                        _image,
                        widget.shopData['uid'] + shopNameController.text,
                      );
                    }
                    Firestore.instance
                        .collection('shops')
                        .where('uid', isEqualTo: widget.shopData.documentID)
                        .limit(1)
                        .getDocuments()
                        .then((doc) {
                      if (openingTime != null && closingTime != null) {
                        if (_image == null) {
                          Firestore.instance
                              .collection('shops')
                              .document(doc.documents[0].documentID)
                              .updateData({
                            "shop_name": shopNameController.text,
                            "shop_contact_name": shopContactController.text,
                            "phone_number": shopNumberController.text,
                            "start_time": openingTime,
                            "end_time": closingTime
                          });
                        } else {
                          Firestore.instance
                              .collection('shops')
                              .document(doc.documents[0].documentID)
                              .updateData({
                            "shop_name": shopNameController.text,
                            "shop_contact_name": shopContactController.text,
                            "phone_number": shopNumberController.text,
                            "shop_image": _url,
                            "start_time": openingTime,
                            "end_time": closingTime
                          });
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else if (openingTime == null && closingTime == null) {
                        if (_image == null) {
                          Firestore.instance
                              .collection('shops')
                              .document(doc.documents[0].documentID)
                              .updateData({
                            "shop_name": shopNameController.text,
                            "shop_contact_name": shopContactController.text,
                            "phone_number": shopNumberController.text,
                          });
                        } else {
                          Firestore.instance
                              .collection('shops')
                              .document(doc.documents[0].documentID)
                              .updateData({
                            "shop_name": shopNameController.text,
                            "shop_contact_name": shopContactController.text,
                            "phone_number": shopNumberController.text,
                            "shop_image": _url
                          });
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                        _showSelectTimeDialog(context);
                      }
                    }).catchError((err) => print(err));
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
  void initState() {
    super.initState();
    shopNameController.text = widget.shopData['shop_name'];
    shopContactController.text = widget.shopData['shop_contact_name'];
    shopNumberController.text = widget.shopData['phone_number'];
    openingTime = widget.shopData['start_time'];
    closingTime = widget.shopData['end_time'];
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
              "Edit Shop Profile",
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
