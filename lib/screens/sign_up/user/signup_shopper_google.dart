import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

class SignUpShopperGoogle extends StatefulWidget {
  SignUpShopperGoogle({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpShopperGoogleState createState() => _SignUpShopperGoogleState();
}

class _SignUpShopperGoogleState extends State<SignUpShopperGoogle> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _userAddressController = TextEditingController();

  String apiKey = "AIzaSyC8mQe0t6T0yJz1DJNW9w0nKgUzKx-aCHM";
  String userAddress = "";
  LatLng userCoordinates;
  String userGeoHash = "";

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
    if (userAddress == "") {
      showAlertDialog(context, "Invalid address", "Please check the entered address.");
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
          .setData({'type': 'user'}, merge: true);

      Firestore.instance.collection('users').document(user.uid)
          .setData({
        'phone_number': _phoneNumberController.text,
        'address': userAddress,
        'token': 'none',
        'uid': user.uid,
        'geohash': userGeoHash,
        'lat': userCoordinates.latitude,
        'lon': userCoordinates.longitude,
        'name': user.displayName,
        'favorites': []
      }, merge: true);

      assert(user.uid == currentUser.uid);
    }

    return 'signInWithGoogle succeeded: ';
  }

  Widget customTextField(IconData iconData, String hint, TextEditingController textEditingController, {enabled=true, KeyType=TextInputType.text}) {
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
                  keyboardType: KeyType,
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
                      return "Invalid entry.";
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
              child: customTextField(Icons.phone, "Contact Number", _phoneNumberController, KeyType: TextInputType.number),
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
                      _userAddressController.text = result.address;
                      userAddress = result.address;
                      userCoordinates = result.latLng;
                      userGeoHash = geoHasher.encode(userCoordinates.longitude, userCoordinates.latitude, precision: 8);
                    });
                  },
                  child: customTextField(Icons.location_on, "Home Location", _userAddressController, enabled: false)),
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

