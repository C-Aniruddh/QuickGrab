import 'dart:async';
import 'package:app/fonts.dart';
import 'package:app/screens/cart/order_payment_page.dart';
import 'package:app/screens/login_page/landing_page.dart';
import 'package:app/screens/utils/order_data_users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_platform/universal_platform.dart';

class OrderCompletedPage extends StatefulWidget {
  OrderCompletedPage({Key key, this.appointmentData}) : super(key: key);

  final DocumentSnapshot appointmentData;

  @override
  _OrderCompletedPageState createState() => _OrderCompletedPageState();
}

class _OrderCompletedPageState extends State<OrderCompletedPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();


  MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    keywords: <String>['shopping', 'online shopping', 'grocery', 'liquor', 'stationary', 'stores', 'offline stores', 'token'],
    contentUrl: 'https://quickgrabb.com',
    testDevices: <String>["336D173B02DF43D5BE59FA7AD3351247"], // Android emulators are considered test devices
  );

  var adInstance = RewardedVideoAd.instance;

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text, style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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

  void showRewardedAd() async {
    try {
      await RewardedVideoAd.instance.load(
          adUnitId: "ca-app-pub-7265536593732931/9713512067", targetingInfo: targetingInfo);
      await RewardedVideoAd.instance.show();
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  showAd() async {
    Future.delayed(Duration(seconds: 3),
        (){
          if (UniversalPlatform.isAndroid){
            showRewardedAd();
          }
        }
    );
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showAd();
  }

  String totalAmount(var items){
    double total = 0;

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      if(item['available']){
        if (item['cost'] == "NA"){
          return "NA";
        }

        total = total +
            (int.parse(item['cost']) *
                int.parse(
                    item['quantity'].toString()));
      }
    }

    return total.toString();
  }

  Widget showCompletedOrder(){
    String total = totalAmount(widget.appointmentData.data['items']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(child: Icon(Icons.check, size: 128, color: Colors.green)),
            ],
          ),
        OrderDataUsers(
          document: widget.appointmentData,
          isInvoice: false,
          displayOTP: true,
          total: total,
          isExpanded: true,
          isShop: false
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.close), color: Colors.black,
            onPressed:(){
              Navigator.pop(context);
            }),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Order Complete', style: TextStyle(fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
      ),
      body: SingleChildScrollView(child: showCompletedOrder()),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Container(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(92, 92, 92, 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(32),
                  topRight: const Radius.circular(32),
                )
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Container()
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: RaisedButton(
                  color: Theme.of(context).accentColor,
                  shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0),
                  ),
                  onPressed: (){
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LandingPage(title: 'Landing Page')), (route) => false);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPaymentPage(items: cartItems, userData: widget.userData,)));
                  },
                  child: ListTile(
                    title: Text("Go to home page", style: TextStyle(color: Colors.white, fontFamily: AppFontFamilies.mainFont)),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.white,)
                  )
                ),
              )
            ],),
          )
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}