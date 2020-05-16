import 'dart:async';
import 'package:app/fonts.dart';
import 'package:app/screens/cart/order_payment_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CartPage extends StatefulWidget {
  CartPage({Key key, this.userData}) : super(key: key);

  final DocumentSnapshot userData;

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  var cartItems = [];

  double billTotal = 0;
  totalCost(var items){
    double cost = 0;
    for (var i = 0; i < items.length; i++){
      var item = items[i];
      cost = cost + (double.parse(item['cost']) * item ['quantity']);
    }
    setState(() {
      billTotal = cost;
    });
  }


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

  Widget singleItem(var items, int index){
    var item = items[index];
    cartItems = items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
              leading: SizedBox(
                child: CircleAvatar(
                  backgroundImage: NetworkImage(item['product']['img_url']),
                ),
              ),
              title: Text(item['product']['item_name'],
                  style: TextStyle(
                      fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
              subtitle: Text("₹" + item['product']['item_price'],
                  style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.remove),
                    onPressed: (){
                      cartItems = items;
                      if (item['quantity'] <= 1){
                        _showInfoDialog(context, "The item has been removed");
                        items.remove(item);
                      } else {
                        item['quantity'] = item['quantity'] - 1;
                        items[index] = item;
                      }
                      Firestore.instance.collection('cart')
                          .document(widget.userData.documentID)
                          .updateData({'cart': items});
                      totalCost(items);
                    },),
                  Text(item['quantity'].toString(), style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                  IconButton(icon: Icon(Icons.add),
                    onPressed: (){
                      cartItems = items;
                      item['quantity'] = item['quantity'] + 1;
                      items[index] = item;
                      Firestore.instance.collection('cart')
                          .document(widget.userData.documentID)
                          .updateData({'cart': items});
                      totalCost(items);
                    },),
                ],
              )
          ),
        ),
      ),
    );
  }

  Widget cartView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: StreamBuilder<DocumentSnapshot>(
            stream: Firestore.instance
                .collection('cart')
                .document(widget.userData.documentID)
                .snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return new Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).accentColor,
                    ),
                  );
                default:
                  cartItems = snapshot.data.data['cart'];
                  var items = snapshot.data.data['cart'];
                  if (items.length < 1) {
                    return Center(
                      child: Text("You do not have any items in your cart.",
                          style: TextStyle(
                              fontFamily: AppFontFamilies.mainFont)),
                    );
                  } else {
                    return new Container(
                        child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return singleItem(items, index);
                            }));
                  }
              }
            },
          )),
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
        leading: IconButton(icon: Icon(Icons.close), color: Colors.black,
            onPressed:(){
              Navigator.pop(context);
            }),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cart', style: TextStyle(fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
      ),
      body: cartView(),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPaymentPage(items: cartItems, userData: widget.userData,)));
                  },
                  child: ListTile(
                    title: Text("Checkout", style: TextStyle(color: Colors.white, fontFamily: AppFontFamilies.mainFont)),
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