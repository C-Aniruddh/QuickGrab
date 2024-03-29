import 'dart:async';
import 'package:app/screens/shop_page/add_general_items.dart';
import 'package:app/screens/shop_page/add_inventory.dart';
import 'package:app/screens/shop_page/edit_items.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:grouped_list/grouped_list.dart';

import '../../fonts.dart';

class ShopMyInventory extends StatefulWidget {
  ShopMyInventory({Key key, this.userData}) : super(key: key);

  DocumentSnapshot userData;

  @override
  _ShopMyInventoryState createState() => _ShopMyInventoryState();
}

class _ShopMyInventoryState extends State<ShopMyInventory> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  _showConfirmationDialog(BuildContext context, product) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Remove this product?"),
          actions: [
            OutlineButton(
              shape: StadiumBorder(),
              borderSide: BorderSide(
                color: Colors.orange,
              ),
              onPressed: () {
                List<dynamic> inventory = widget.userData.data['inventory'];
                inventory.remove(product.documentID);
                Firestore.instance
                    .collection('shops')
                    .document(widget.userData.documentID)
                    .updateData({'inventory': inventory});
                Firestore.instance
                    .collection('products')
                    .document(product.documentID)
                    .delete();
                Navigator.pop(context);
              },
              child: Text(
                "Remove",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            OutlineButton(
              shape: StadiumBorder(),
              borderSide: BorderSide(
                color: Colors.orange,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> categoriesByIndustry(String industry) {
    if (industry == 'Agriculure') {
      return ['Select Category', 'Pesticides', 'Grains', 'Seeds', 'Other'];
    } else if (industry == 'Consurmer durables') {
      return ['Select Category', 'Other'];
    } else if (industry == 'Education') {
      return ['Select Category', 'Other'];
    } else if (industry == 'Engineering and capital goods') {
      return [
        'Select Category',
        'Electronic Parts',
        'Electronic gadgets',
        'Other'
      ];
    } else if (industry == 'Gems and Jwellery') {
      return [
        'Select Category',
        'Ring',
        'Necklace',
        'Pendant',
        'Gold',
        'Silver',
        'Other'
      ];
    } else if (industry == 'Grocery') {
      return [
        'Select Category',
        'Beverages',
        'Rice',
        'Atta',
        'Bread',
        'Canned/Jarred Goods',
        'Dairy/Tea',
        'Baking Goods',
        'Frozen Goods',
        'Snacks',
        'Spices',
        'Meat',
        'Milk Produce',
        'Grains',
        'Cleaners',
        'Spreads and sauces',
        'Sweets'
            'Paper Goods',
        'Personal Care',
        'Other'
      ];
    } else if (industry == 'Liquor') {
      return [
        'Select Category',
        'Whiskey',
        'Beer',
        'Brandy',
        'Vodka',
        'Rum',
        'Gin',
        'Tequila',
        'Wine',
        'Other'
      ];
    } else if (industry == 'Manufacturing') {
      return ['Select Category', 'Other'];
    } else if (industry == 'Oil and Gas') {
      return ['Select Category', 'Petrol/Diesel/CNG', 'Other'];
    } else if (industry == 'Pharmaceuticals') {
      return ['Select Category', 'General', 'Prescription', 'Other'];
    } else if (industry == 'Retail') {
      return ['Select Category', 'Clothing', 'Socks and shoes', 'Other'];
    } else if (industry == 'Stationary') {
      return [
        'Select Category',
        'Paper',
        'Envelopes',
        'Chart Paper',
        'Books',
        'Study Material',
        'Stapler',
        'Notepads',
        'Notebooks',
        'Pens/Pencils',
        'Journal Sheets',
        'Other'
      ];
    } else if (industry == 'Textile') {
      return ['Select Category', 'Other'];
    } else if (industry == 'Vegetables and Fruits') {
      return ['Select Category', 'Vegetables', 'Fruits', 'Extras', 'Other'];
    } else {
      return ['Select Category', 'Other'];
    }
  }

  Widget buildProductGrid() {
    print(widget.userData.data['inventory'].length);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
          child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('products')
            .where('shop_uid', isEqualTo: widget.userData.documentID)
            .orderBy('item_name', descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: CircularProgressIndicator(
                  backgroundColor: Theme.of(context).accentColor,
                ),
              );
            default:
              List<DocumentSnapshot> filterList = snapshot.data.documents;
              if (filterList.length < 1) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "You do not have any products.\nAdd your products using the '+' button at the bottom.",
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            new SizedBox(
                              height: 10.0,
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: new Center(
                                child: new Container(
                                  margin: new EdgeInsetsDirectional.only(
                                      start: 1.0, end: 1.0),
                                  height: 2.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Text("OR"),
                            new SizedBox(
                              height: 10.0,
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: new Center(
                                child: new Container(
                                  margin: new EdgeInsetsDirectional.only(
                                      start: 1.0, end: 1.0),
                                  height: 2.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                        child: Text(
                          "Add items to your inventory from our pre-defined list of products.",
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Center(
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                side: BorderSide(
                                  color: Theme.of(context).accentColor,
                                )),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StandardInventory(
                                    industry: widget.userData.data['industry'],
                                    shopDetails: widget.userData,
                                  ),
                                ),
                              );
                            },
                            color: Theme.of(context).accentColor,
                            textColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Add Pre-defined items"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: GroupedListView(
                    useStickyGroupSeparators: false,
                    elements: filterList,
                    groupBy: (element) => element['item_category'],
                    order: GroupedListOrder.ASC,
                    groupSeparatorBuilder: (groupByValue) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('$groupByValue'),
                      );
                    },
                    itemBuilder: (BuildContext context, element) {
                      return InkWell(
                          onTap: () {},
                          child: Card(
                              child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditInventory(
                                                itemData: element,
                                              ),
                                            ),
                                          );
                                        }),
                                    IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          _showConfirmationDialog(
                                              context, element);
                                        }),
                                  ],
                                ),
                                leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(element.data['img_url'])),
                                title: Text(element.data['item_name'],
                                    style: TextStyle(
                                        fontFamily: AppFontFamilies.mainFont)),
                                subtitle: Text(
                                  "₹" +
                                      element.data['item_price'] +
                                      "  |  Size: " +
                                      element.data['item_quantity'].toString(),
                                  style: TextStyle(
                                      fontFamily: AppFontFamilies.mainFont),
                                )),
                          ))
                          /* Card(
                              child: Container(
                                width: 160.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                          height: 120,
                                          width: 160,
                                          child: Hero(
                                            tag: filterList[index].documentID,
                                            child: Image(
                                                image: NetworkImage(
                                                    filterList[index].data['img_url']),
                                                height: 128,
                                                width: 128),
                                          )),
                                    ),
                                    Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                            child: ListTile(
                                              title: Text(
                                                  filterList[index].data['item_name'],
                                                  style: TextStyle(
                                                      fontFamily:
                                                      AppFontFamilies.mainFont)),
                                            ))),

                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: RaisedButton(
                                          color: Theme.of(context).accentColor,
                                          shape: new RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.circular(30.0),
                                          ),
                                          onPressed: (){
                                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScheduledOrders(userData: userData,)));
                                          },
                                          child: Icon(Icons.edit, color: Colors.white)
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ),*/
                          );
                    },
                  ),
                );
              }
          }
        },
      )),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    SystemChannels.lifecycle.setMessageHandler((msg) {
      debugPrint('SystemChannels> $msg');
      if (msg == AppLifecycleState.resumed.toString()) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).accentColor,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () {
            List<String> categories =
                categoriesByIndustry(widget.userData.data['industry']);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddInventory(
                          shopData: widget.userData,
                          categories: categories,
                        )));
          }),
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
          child: Text("My Inventory",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildProductGrid(),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
