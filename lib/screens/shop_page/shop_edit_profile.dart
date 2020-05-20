import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
                    side: BorderSide(color: Colors.orangeAccent)),
                onPressed: () async {
                  _showUploadChoiceDialog(context);
                },
                color: Colors.orangeAccent,
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.orangeAccent)),
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
                        })
                        .catchError((err) => print(err))
                        .then((value) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                  }
                },
                color: Colors.orangeAccent,
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
    // TODO: implement initState
    super.initState();
    shopNameController.text = widget.shopData['shop_name'];
    shopContactController.text = widget.shopData['shop_contact_name'];
    shopNumberController.text = widget.shopData['phone_number'];
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
