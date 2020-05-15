import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../fonts.dart';

class AddInventory extends StatefulWidget {
  AddInventory({Key key, this.shopData}) : super(key: key);

  final DocumentSnapshot shopData;

  @override
  _AddInventoryState createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  DocumentSnapshot inventoryData;
  File _image;
  File croppedImage;
  final _formKey = GlobalKey<FormState>();
  String _uploadedFileURL;

  TextEditingController itemNameController = new TextEditingController();
  TextEditingController itemPriceController = new TextEditingController();
  TextEditingController itemQuantityController = new TextEditingController();
  TextEditingController itemDescriptionController = new TextEditingController();

  final databaseReference = FirebaseDatabase.instance.reference();

  Future getGalleryImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Future getCameraImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = image;
    });
  }

  _showUploadChoiceDialog(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select image from...',
              style: TextStyle(fontFamily: AppFontFamilies.mainFont),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Gallery',
                      style: TextStyle(
                          fontFamily: AppFontFamilies.mainFont, fontSize: 18.0),
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
                      style: TextStyle(
                          fontFamily: AppFontFamilies.mainFont, fontSize: 18.0),
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

  Future<Null> _cropImage(File imageFile) async {
    croppedImage = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      maxWidth: 2048,
      maxHeight: 2048,
    );
    setState(() {
      this._image = croppedImage;
    });
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      this._image = image;
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

  _showDialog(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Adding to inventory', style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
            content: SingleChildScrollView(
              child: Text("Adding new item...", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
            ),
          );
        });
  }

  _showErrorDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Text("Something went wrong, please try again."),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Try Again',
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Text(
                  'Back',
                ),
              ),
            ],
          );
        });
  }

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OKAY',
                ),
              ),
            ],
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
          width: 275.0,
          height: 275.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),

          ),
          child: Icon(
            Icons.add_a_photo,
            size: 128.0,
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
                    hintStyle: TextStyle(
                      fontFamily: AppFontFamilies.mainFont,
                    )),
                controller: textEditingController,
                style: new TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                ),
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

  Widget customLargeTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 96.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * .90,
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
                maxLines: 3,
                enabled: enabled,
                keyboardType: keyType,
                decoration: new InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: AppFontFamilies.mainFont,
                    )),
                controller: textEditingController,
                style: new TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                ),
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
                          ? "Add an picture"
                          : "Retake picture".toUpperCase(),
                      style: TextStyle(fontSize: 14, fontFamily: AppFontFamilies.mainFont)),
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
          customTextField(Icons.text_fields, "Item Name", itemNameController),
          customTextField(Icons.attach_money, "Item Price", itemPriceController,
              keyType: TextInputType.number),
          customTextField(Icons.format_list_numbered,
              "Item Quantity (Optional)", itemQuantityController,
              keyType: TextInputType.number, validate: false),
          customLargeTextField(Icons.description,
              "\nItem Description (Optional)", itemDescriptionController,
              validate: false),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Center(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.orangeAccent)),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    if (itemNameController.text.isNotEmpty &&
                        itemPriceController.text.isNotEmpty) {
                      _showDialog(context);
                      String _url = await uploadFile(_image, widget.shopData['uid'] + itemNameController.text);
                      Firestore.instance.collection('products').add({
                        "shop_uid": widget.shopData['uid'],
                        "item_name": itemNameController.text,
                        "item_price": itemPriceController.text,
                        "item_quantity": itemQuantityController.text,
                        "item_description": itemDescriptionController.text,
                        "img_url": _url
                      }).then((result) {
                        Firestore.instance.collection('shops')
                        .document(widget.shopData.documentID)
                        .get()
                        .then((doc){
                          List<dynamic> inventory = doc.data['inventory'];
                          inventory.add(result.documentID);
                          Firestore.instance.collection('shops')
                          .document(widget.shopData.documentID)
                          .updateData({'inventory': inventory});
                        });
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }).catchError((err) => print(err));
                    }
                  }
                },
                color: Colors.orangeAccent,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Add to inventory".toUpperCase(),
                      style: TextStyle(fontSize: 14, fontFamily: AppFontFamilies.mainFont)),
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
            child: Text("Add Item to Inventory",
                style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
          ),
        ),
        body: SingleChildScrollView(
          child: buildBody(),
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
