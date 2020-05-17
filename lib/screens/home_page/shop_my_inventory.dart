import 'dart:async';
import 'package:app/screens/shop_page/add_inventory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';


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


  List<String> categoriesByIndustry(String industry){
    if (industry == 'Agriculure'){
      return ['Select Category', 'Pesticides', 'Grains', 'Seeds', 'Other'];
    } else if (industry == 'Consurmer durables'){
      return ['Select Category','Other'];
    } else if (industry == 'Education'){
      return ['Select Category','Other'];
    } else if (industry == 'Engineering and capital goods'){
      return ['Select Category','Electronic Parts', 'Electronic gadgets',  'Other'];
    } else if (industry == 'Gems and Jwellery'){
      return ['Select Category','Ring', 'Necklace', 'Pendant', 'Gold', 'Silver',  'Other'];
    } else if (industry == 'Grocery') {
      return ['Select Category','Beverages', 'Bread/Bakery', 'Canned/Jarred Goods', 'Dairy', 'Baking Goods',
        'Frozen Goods', 'Snacks', 'Spices', 'Meat', 'Milk Produce', 'Grains', 'Cleaners',
        'Paper Goods', 'Personal Care', 'Other'];
    } else if (industry == 'Liquor'){
      return ['Select Category','Whiskey', 'Beer', 'Brandy', 'Vodka', 'Rum', 'Gin', 'Tequila',  'Other'];
    } else if (industry == 'Manufacturing'){
      return ['Select Category','Other'];
    } else if (industry == 'Oil and Gas'){
      return ['Select Category','Petrol', 'Diesel', 'CNG', 'Other'];
    } else if (industry == 'Pharmaceuticals'){
      return ['Select Category','General', 'Prescription', 'Other'];
    } else if (industry == 'Retail'){
      return ['Select Category','Tshirts', 'Pants', 'Jeans', 'Shirts', 'Inners', 'Jackets', 'Accessories', 'Socks and shoes',  'Other'];
    } else if (industry == 'Stationary'){
      return ['Select Category','Paper', 'Envelopes', 'Chart Paper', 'Books', 'Study Material', 'Stapler',
        'Notepads', 'Notebooks', 'Pens/Pencils', 'Journal Sheets', 'Other'];
    } else if (industry == 'Textile'){
      return ['Select Category','Other'];
    } else if (industry == 'Vegetables and Fruits'){
      return ['Select Category','Vegetables', 'Fruits', 'Extras',  'Other'];
    } else {
      return ['Select Category','Other'];
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
                      child: Text("You do not have any products.", style:
                      TextStyle(fontFamily: AppFontFamilies.mainFont)),
                    );
                  } else {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: ListView.builder(
                        itemCount: filterList.length,
                        //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        //    crossAxisCount: 2, childAspectRatio: (3 / 4)),
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            onTap: (){
                            },
                            child: Card(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: (){
                                    List<dynamic> inventory = widget.userData.data['inventory'];
                                    inventory.remove(filterList[index].documentID);
                                    Firestore.instance.collection('shops')
                                        .document(widget.userData.documentID)
                                        .updateData({'inventory': inventory});
                                    Firestore.instance.collection('products')
                                        .document(filterList[index].documentID)
                                        .delete();
                                  }
                                ),
                              leading: CircleAvatar(
                          backgroundImage: NetworkImage(filterList[index].data['img_url'])),
                                title: Text(
                                  filterList[index].data['item_name'],
                                  style: TextStyle(
                                  fontFamily:
                                  AppFontFamilies.mainFont)),
                                subtitle:   Text(
                                  "₹" + filterList[index].data['item_price'] + "  |  Size: " + filterList[index].data['item_quantity'].toString(),
                                  style: TextStyle(
                                      fontFamily:
                                      AppFontFamilies.mainFont),
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
    SystemChannels.lifecycle.setMessageHandler((msg){
      debugPrint('SystemChannels> $msg');
      if(msg==AppLifecycleState.resumed.toString())setState((){});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: (){
          List<String> categories = categoriesByIndustry(widget.userData.data['industry']);
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddInventory(shopData: widget.userData,categories: categories,)));
        }
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(icon: Icon(Icons.close),
        color: Colors.black,
        onPressed: (){
          Navigator.pop(context);
        },),
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