import 'dart:async';
import 'package:app/fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CartPage extends StatefulWidget {
  CartPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();


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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                    leading: SizedBox(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage('https://www.ikea.com/in/en/images/products/tjena-storage-box-with-lid__0711014_PE727895_S5.JPG'),
                      ),
                    ),
                    title: Text('Item Name',
                        style: TextStyle(
                            fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
                    subtitle: Text('Item Cost',
                        style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.remove),
                          onPressed: (){
                          },),
                        Text("0", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                        IconButton(icon: Icon(Icons.add),
                          onPressed: (){
                          },),
                      ],
                    )
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                    leading: SizedBox(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage('https://www.ikea.com/in/en/images/products/tjena-storage-box-with-lid__0711014_PE727895_S5.JPG'),
                      ),
                    ),
                    title: Text('Item Name',
                        style: TextStyle(
                            fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
                    subtitle: Text('Item Cost',
                        style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.remove),
                          onPressed: (){
                          },),
                        Text("0", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                        IconButton(icon: Icon(Icons.add),
                          onPressed: (){
                          },),
                      ],
                    )
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                    leading: SizedBox(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage('https://www.ikea.com/in/en/images/products/tjena-storage-box-with-lid__0711014_PE727895_S5.JPG'),
                      ),
                    ),
                    title: Text('Item Name',
                        style: TextStyle(
                            fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
                    subtitle: Text('Item Cost',
                        style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.remove),
                          onPressed: (){
                          },),
                        Text("0", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                        IconButton(icon: Icon(Icons.add),
                          onPressed: (){
                          },),
                      ],
                    )
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                    leading: SizedBox(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage('https://www.ikea.com/in/en/images/products/tjena-storage-box-with-lid__0711014_PE727895_S5.JPG'),
                      ),
                    ),
                    title: Text('Item Name',
                        style: TextStyle(
                            fontSize: 24, fontFamily: AppFontFamilies.mainFont)),
                    subtitle: Text('Item Cost',
                        style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.remove),
                          onPressed: (){
                          },),
                        Text("0", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                        IconButton(icon: Icon(Icons.add),
                          onPressed: (){
                          },),
                      ],
                    )
                ),
              ),
            ),
          ),
        ],
      ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Items: 10", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
                      Text("Total: 800", style: TextStyle(fontSize: 20, fontFamily: AppFontFamilies.mainFont))
                    ],
                  ),
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