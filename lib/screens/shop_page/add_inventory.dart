import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app/screens/shop_page/item_variant_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../fonts.dart';

class AddInventory extends StatefulWidget {
  AddInventory({Key key, this.shopData, this.categories}) : super(key: key);

  final DocumentSnapshot shopData;
  final List<String> categories;

  @override
  _AddInventoryState createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  DocumentSnapshot inventoryData;
  File _image;
  File croppedImage;
  final _formKey = GlobalKey<FormState>();
  String _uploadedFileURL;

  String _categorySelect = 'Select Category';

  List<Widget> itemVariants = new List<Widget>();
  List items = new List();

  TextEditingController itemNameController = new TextEditingController();
  TextEditingController itemPriceController = new TextEditingController();
  TextEditingController itemQuantityController = new TextEditingController();
  TextEditingController itemDescriptionController = new TextEditingController();

  final databaseReference = FirebaseDatabase.instance.reference();

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

  _showDialog(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Adding to inventory',
                style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
            content: SingleChildScrollView(
              child: Text("Adding new item...",
                  style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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
                      return null;
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

  String itemQu() {
    if (widget.shopData.data['industry'] == 'Liquor') {
      return "Item Quantity (in ml) (e.g 1000ml)";
    } else {
      return "Item Quantity (1 Dozen, 1kg, 500gm, etc)";
    }
  }

  Widget buildVariant(
      {String size, String quantity, String unit, String price}) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "Size: " + size + "  " + unit,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "Quantity: " + quantity,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "Price: " + price,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
            padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
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
                          fontSize: 14, fontFamily: AppFontFamilies.mainFont)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 56.0,
              margin: EdgeInsets.all(8.0),
              child: new Container(
                padding: const EdgeInsets.only(left: 8, right: 5),
                width: MediaQuery.of(context).size.width * .90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
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
                      child: new IconButton(
                          icon: new Icon(
                            Icons.business,
                          ),
                          onPressed: null),
                    ),
                    new Flexible(
                      child: new DropdownButtonHideUnderline(
                        child: new DropdownButton(
                          iconDisabledColor: Colors.grey,
                          iconEnabledColor: Colors.grey,
                          hint: Text("Select Category",
                              style: TextStyle(
                                  fontFamily: AppFontFamilies.mainFont,
                                  color: Colors.grey)),
                          value: _categorySelect,
                          isDense: true,
                          onChanged: (String newValue) {
                            setState(() {
                              _categorySelect = newValue;
                            });
                          },
                          items: widget.categories.map((String value) {
                            return new DropdownMenuItem(
                              value: value,
                              child: new Text(
                                value,
                                style: TextStyle(
                                  fontFamily: AppFontFamilies.mainFont,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          itemVariants.length == 0
              ? Container(
                  margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                  width: MediaQuery.of(context).size.width * .85,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "No variants added yet. Press the 'Add a variant' button to add one.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                  width: MediaQuery.of(context).size.width * .85,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: itemVariants,
                    ),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(32, 0, 16, 12),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.orangeAccent)),
                  onPressed: () async {
                    var data = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      child: ItemVariantDialog(),
                    );
                    if (data != null) {
                      setState(() {
                        itemVariants.add(buildVariant(
                            size: data[0],
                            unit: data[1],
                            quantity: data[2],
                            price: data[3]));
                      });
                      items.add({
                        "size": data[0],
                        "unit": data[1],
                        "quantity": data[2],
                        "price": data[3],
                      });
                    }
                  },
                  color: Colors.orangeAccent,
                  textColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Add a variant",
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 16, 12),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.orangeAccent)),
                  onPressed: () async {
                    setState(() {
                      itemVariants.clear();
                    });
                    items.clear();
                  },
                  color: Colors.orangeAccent,
                  textColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Remove all variants",
                    ),
                  ),
                ),
              ),
            ],
          ),
          customLargeTextField(
            Icons.description,
            "\nItem Description (Optional)",
            itemDescriptionController,
            validate: false,
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
                    if (itemNameController.text.isNotEmpty) {
                      if (_categorySelect != 'Select Category') {
                        if (items.length != 0) {
                          _showDialog(context);
                          String itemPrice = "NA";
                          // TODO: Handle adding to firebase
                          itemPrice = itemPriceController.text.toString();
                          String _url;
                          if (_image == null) {
                            String url =
                                "https://pixabay.com/api/?key=9678820-6ac123539192973cfe0c470bf&q=" +
                                    _categorySelect +
                                    "&category=food&order=popular";
                            var response = await http.get(url);
                            var data = json.decode(response.body);
                            var hits = data['hits'];
                            _url = hits[0]['previewURL'];
                            print(_url);
                          } else {
                            _url = await uploadFile(
                                _image,
                                widget.shopData['uid'] +
                                    itemNameController.text);
                          }
                          Firestore.instance.collection('products').add({
                            "shop_uid": widget.shopData['uid'],
                            "item_name": itemNameController.text,
                            "item_price": itemPrice,
                            "item_quantity": itemQuantityController.text,
                            "item_description": itemDescriptionController.text,
                            "item_category": _categorySelect,
                            "shop_industry": widget.shopData['industry'],
                            "img_url": _url
                          }).then((result) {
                            Firestore.instance
                                .collection('shops')
                                .document(widget.shopData.documentID)
                                .get()
                                .then((doc) {
                              List<dynamic> inventory = doc.data['inventory'];
                              inventory.add(result.documentID);
                              Firestore.instance
                                  .collection('shops')
                                  .document(widget.shopData.documentID)
                                  .updateData({'inventory': inventory});
                            });
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }).catchError((err) => print(err));
                        } else {
                          _showInfoDialog(
                            context,
                            "No variants added yet. Press the 'Add a variant' button to add one.",
                          );
                        }
                      } else {
                        _showInfoDialog(
                            context, "Please select item category.");
                      }
                    } else {
                      _showInfoDialog(
                          context, "Please enter name of the Item.");
                    }
                  } else {
                    _showInfoDialog(
                        context, "Please check the form for errors.");
                  }
                },
                color: Colors.orangeAccent,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Add to inventory".toUpperCase(),
                      style: TextStyle(
                          fontSize: 14, fontFamily: AppFontFamilies.mainFont)),
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
