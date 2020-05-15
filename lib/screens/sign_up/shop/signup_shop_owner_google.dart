import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

class SignUpShopOwnerGoogle extends StatefulWidget {
  SignUpShopOwnerGoogle({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpShopOwnerGoogleState createState() => _SignUpShopOwnerGoogleState();
}

class _SignUpShopOwnerGoogleState extends State<SignUpShopOwnerGoogle> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _shopNameController = TextEditingController();
  TextEditingController _shopAddressController = TextEditingController();
  TextEditingController _shopContactNameController = TextEditingController();
  TextEditingController _shopGSTController = TextEditingController();

  String apiKey = "AIzaSyC8mQe0t6T0yJz1DJNW9w0nKgUzKx-aCHM";
  String shopAddress = "";
  LatLng shopCoordinates;
  String shopGeoHash = "";

  List<String> _industryList = <String>[
    'Select Industry',
    'Agriculure',
    'Consurmer durables',
    'Education',
    'Engineering and capital goods',
    'Gems and Jwellery',
    'Grocery',
    'Liquor',
    'Manufacturing',
    'Oil and Gas',
    'Pharmaceuticals',
    'Retail',
    'Stationary'
    'Textile',
    'Vegetables and Fruits',
    'Other'
  ];
  String _industrySelect = 'Select Industry';

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  showAlertDialog(BuildContext context, String title, String content) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
      content: Text(content, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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

  Future<String> signInWithGoogle() async {
    if (_shopNameController.text.length == 0){
      showAlertDialog(context, "Invalid shop name", "Please check the entered shop name.");
    } else if (_industrySelect == "Select Industry") {
      showAlertDialog(context, "Invalid shop industry", "Please check the selected shop industry.");
    } else if (shopAddress == "") {
      showAlertDialog(context, "Invalid shop address", "Please check the entered shop address.");
    } else if (_shopGSTController.text.length == 0){
      showAlertDialog(context, "Invalid GST", "Please check the entered GST Number.");
    } else if (_shopContactNameController.text.length == 0) {
      showAlertDialog(context, "Invalid contact name", "Please check the entered shop contact name.");
    } else if (_phoneNumberController.text.length == 0){
      showAlertDialog(context, "Invalid phone number", "Please check the entered phone number.");
    } else {
      final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final AuthResult authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final FirebaseUser user = authResult.user;

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
      assert(user.uid == currentUser.uid);

      Firestore.instance.collection('uid_type').document(user.uid)
          .setData({'type': 'shop'}, merge: true);

      Firestore.instance.collection('shops').document(user.uid)
          .setData({
        'industry': _industrySelect,
        'limit': 10,
        'phone_number': _phoneNumberController.text,
        'shop_GST': _shopGSTController.text,
        'shop_address': shopAddress,
        'shop_contact_name': _shopContactNameController.text,
        'shop_name': _shopNameController.text,
        'token': 'none',
        'uid': user.uid,
        'shop_geohash': shopGeoHash,
        'shop_lat': shopCoordinates.latitude,
        'shop_lon': shopCoordinates.longitude,
        'shop_image': 'https://i.imgur.com/HCw2Ho7.png',
        'shop_payment_methods': ['Cash'],
        'inventory': []
      }, merge: true);

      assert(user.uid == currentUser.uid);
    }

    return 'signInWithGoogle succeeded: ';
  }

  Widget customTextField(IconData iconData, String hint, TextEditingController textEditingController, {enabled=true, keyType=TextInputType.text}) {
    return Container(
        height: 56.0,
        margin: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
        child: new Container(
          padding:
          const EdgeInsets.only(left: 8, right: 5),
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
                    icon: Icon(iconData),
                    onPressed: null),
              ),
              new Flexible(
                child: new TextFormField(
                  enabled: enabled,
                  keyboardType: keyType,
                  decoration: new InputDecoration
                      .collapsed(
                      hintText: hint,
                      hintStyle: TextStyle(
                          fontFamily:
                          AppFontFamilies.mainFont,)),
                  controller: textEditingController,
                  style: new TextStyle(
                    fontFamily: AppFontFamilies.mainFont,
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Invalid Entry.";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Image(image: AssetImage('assets/images/sign_up_form.png'), height: 250, width: 300,),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Sign up with Google!", style: TextStyle(fontSize: 24, fontFamily: AppFontFamilies.mainFont))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("We will need a few details.", style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: customTextField(Icons.info, "Shop Name", _shopNameController),
            ),
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
                              hint: Text("Select Industry",
                                  style: TextStyle(
                                      fontFamily: AppFontFamilies.mainFont,
                                      color: Colors.grey)),
                              value: _industrySelect,
                              isDense: true,
                              onChanged: (String newValue) {
                                setState(() {
                                  _industrySelect = newValue;
                                });
                              },
                              items: _industryList.map((String value) {
                                return new DropdownMenuItem(
                                  value: value,
                                  child: new Text(
                                    value,
                                    style: TextStyle(
                                        fontFamily: AppFontFamilies.mainFont,),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: InkWell(
                  onTap: () async {
                    LocationResult result = await showLocationPicker(context, apiKey);
                    print(result.address);
                    print(result.latLng);
                    GeoHasher geoHasher = GeoHasher();
                    setState(() {
                      _shopAddressController.text = result.address;
                      shopAddress = result.address;
                      shopCoordinates = result.latLng;
                      shopGeoHash = geoHasher.encode(shopCoordinates.longitude, shopCoordinates.latitude, precision: 8);
                    });
                  },
                  child: customTextField(Icons.location_on, "Shop Location", _shopAddressController, enabled: false)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: customTextField(Icons.assignment, "Shop GST Number", _shopGSTController),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: customTextField(Icons.phone, "Contact Number", _phoneNumberController, keyType: TextInputType.number),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: customTextField(Icons.account_circle, "Contact Name", _shopContactNameController),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Center(child:RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)),
                onPressed: () async {
                  await signInWithGoogle();
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                color: Colors.red,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Complete Sign Up".toUpperCase(),
                      style: TextStyle(fontSize: 14)),
                ),
              ),
              )
            ),
            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}

