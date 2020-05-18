import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

class SignUpShopOwnerFacebook extends StatefulWidget {
  SignUpShopOwnerFacebook({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpShopOwnerFacebookState createState() => _SignUpShopOwnerFacebookState();
}

class _SignUpShopOwnerFacebookState extends State<SignUpShopOwnerFacebook> {

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
    'Grocery',
    'Liquor',
    'Manufacturing',
    'Oil and Gas',
    'Pharmaceuticals',
    'Retail',
    'Stationary',
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

  _showSignUpDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Text(text),
                  ),
                ],
              ),
            ),
          );
        });
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

  String profilePicByIndustry(String industry){
    if (industry == 'Agriculure'){
      return 'https://i.imgur.com/jfVIvEd.png';
    } else if (industry == 'Consurmer durables'){
      return 'https://i.imgur.com/vadpYXZ.jpg';
    } else if (industry == 'Education'){
      return 'https://i.imgur.com/ILuBFVr.jpg';
    } else if (industry == 'Engineering and capital goods'){
      return 'https://i.imgur.com/95N4cM6.jpg';
    } else if (industry == 'Gems and Jwellery'){
      return 'https://i.imgur.com/rWk5b3y.jpg';
    } else if (industry == 'Grocery') {
      return 'https://i.imgur.com/RnQVr3I.jpg';
    } else if (industry == 'Liquor'){
      return 'https://i.imgur.com/cTgZo71.jpg';
    } else if (industry == 'Manufacturing'){
      return 'https://i.imgur.com/95N4cM6.jpg';
    } else if (industry == 'Oil and Gas'){
      return 'https://i.imgur.com/R77k8CD.jpg';
    } else if (industry == 'Pharmaceuticals'){
      return 'https://i.imgur.com/gXcyC4w.jpg';
    } else if (industry == 'Retail'){
      return 'https://i.imgur.com/DjW5799.jpg';
    } else if (industry == 'Stationary'){
      return 'https://i.imgur.com/yHXRj55.jpg';
    } else if (industry == 'Textile'){
      return 'https://i.imgur.com/DjW5799.jpg';
    } else if (industry == 'Vegetables and Fruits'){
      return 'https://i.imgur.com/MjbrTlI.jpg';
    } else {
      return 'https://i.imgur.com/RnQVr3I.jpg';
    }
  }

  Future<String> signInWithFacebook() async {
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

      var facebookLogin = new FacebookLogin();
      _showSignUpDialog(context, "Signing you up...");
      var result = await facebookLogin.logIn(['email', 'public_profile']);

      FirebaseUser user;

      if (result.status == FacebookLoginStatus.loggedIn){
        FacebookAccessToken facebookAccessToken = result.accessToken;
        AuthCredential authCredential = FacebookAuthProvider.getCredential(accessToken: facebookAccessToken.token);

        user = (await FirebaseAuth.instance.signInWithCredential(authCredential)).user;
      }

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
        'shop_image': profilePicByIndustry(_industrySelect),
        'shop_payment_methods': ['Cash'],
        'inventory': []
      }, merge: true);

      assert(user.uid == currentUser.uid);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
              child: Image(image: AssetImage('assets/images/facebook_logo.png'), height: 250, width: 300,),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Sign up with Facebook!", style: TextStyle(fontSize: 24, fontFamily: AppFontFamilies.mainFont))),
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
                    LocationResult result = await showLocationPicker(context, apiKey, initialCenter: LatLng(19.074376, 72.871137), requiredGPS: false);
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
              padding: const EdgeInsets.all(16.0),
              child: FacebookSignInButton(onPressed: () async {
                await signInWithFacebook();

              }),
            ),
            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}

