import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:app/screens/cart/cart_page.dart';
import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app/screens/home_page/user_home_page.dart';
import 'package:app/screens/utils/custom_sliver_appbar_delegate.dart';
import 'package:app/screens/utils/custom_responsive_grid.dart';

import '../../fonts.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key key, this.shopDetails, this.userDetails}) : super(key: key);

  final DocumentSnapshot shopDetails;
  final DocumentSnapshot userDetails;

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  CameraPosition _kGooglePlex;
  Completer<GoogleMapController> _controller = Completer();

  bool mapLoaded = false;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  final TextEditingController _textEditingController =
      new TextEditingController();

  List categories;

  void _add() {
    var markerIdVal = 'marker';
    final MarkerId markerId = MarkerId(markerIdVal);

    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
          widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']),
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  void setupMap() async {
    _kGooglePlex = CameraPosition(
      target: LatLng(
          widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']),
      zoom: 17,
    );
    _add();
  }

  void setup() async {
    setupMap();
    setState(() {
      mapLoaded = true;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    setup();
    getCategories();
    super.initState();
  }

  _showInformationDialog(BuildContext context, String text) {
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
                  'Okay',
                ),
              ),
            ],
          );
        });
  }

  _showDialog() async {
    await showDialog<String>(
      context: context,
      builder: (ctxt) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text("Request an appointment"),
            TextFormField(
              maxLines: 5,
              autofocus: true,
              decoration:
                  InputDecoration(labelText: 'What do you want to buy?'),
              keyboardType: TextInputType.multiline,
              controller: _textEditingController,
            ),
          ]),
          actions: <Widget>[
            FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            FlatButton(
                child: Text('Request Appointment'),
                onPressed: () async {
                  var rng = new Random();
                  var now = new DateTime.now();
                  await Firestore.instance.collection('appointments').add({
                    'timestamp': now,
                    'items': _textEditingController.text,
                    'target_shop': widget.shopDetails['uid'],
                    'shopper_uid': widget.userDetails['uid'],
                    'shopper_name': widget.userDetails['name'],
                    'shop_name': widget.shopDetails['shop_name'],
                    'shop_geohash': widget.shopDetails['shop_geohash'],
                    'appointment_status': 'pending',
                    'appointment_start': null,
                    'appointment_end': null,
                    'otp': (rng.nextInt(10000) + 1000).toString()
                  }).then((value) async {
                    String title = "New appointment request";
                    String body = widget.userDetails['name'] +
                        " has requested an appointment.";
                    await Firestore.instance.collection('notifications').add({
                      'sender_type': "users",
                      'receiver_uid': widget.shopDetails['uid'],
                      'title': title,
                      'body': body,
                      'read': false,
                    });
                  });
                  Navigator.pop(context);
                  _showInformationDialog(
                      context, "Your appointment was successfully requested");
                })
          ],
        );
      },
    );
  }

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text,
                    style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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

  Widget buildProductGrid(String category) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: category == "All Products"
            ? Firestore.instance
                .collection('products')
                .where('shop_uid', isEqualTo: widget.shopDetails.documentID)
                .snapshots()
            : Firestore.instance
                .collection('products')
                .where('shop_uid', isEqualTo: widget.shopDetails.documentID)
                .where('item_category', isEqualTo: category)
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 96.0, 16.0, 16.0),
                    child: Text(
                        "There are no products in this category available."),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    primary: true,
                    shrinkWrap: true,
                    itemCount: filterList.length,
                    //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //    crossAxisCount: 2, childAspectRatio: (3/4)),
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  filterList[index].data['img_url']),
                            ),
                            subtitle: Text(
                                "₹" + filterList[index].data['item_price'],
                                style: TextStyle(
                                    fontFamily: AppFontFamilies.mainFont)),
                            title: Text(filterList[index].data['item_name'],
                                style: TextStyle(
                                    fontFamily: AppFontFamilies.mainFont)),
                            trailing: IconButton(
                              icon: Icon(Icons.add_shopping_cart),
                              onPressed: () {
                                Firestore.instance
                                    .collection('cart')
                                    .document(widget.userDetails.documentID)
                                    .get()
                                    .then((document) {
                                  List<dynamic> cart;
                                  if (document.exists) {
                                    cart = document.data['cart'];
                                  } else {
                                    cart = [];
                                  }

                                  if (cart.length < 1) {
                                    cart.add({
                                      'user_uid': widget.userDetails.documentID,
                                      'product': filterList[index].data,
                                      'timestamp':
                                          DateTime.now().millisecondsSinceEpoch,
                                      'cost':
                                          filterList[index].data['item_price'],
                                      'quantity': 1,
                                      'productID': filterList[index].documentID
                                    });
                                  } else {
                                    List<String> productsInCart = [];

                                    for (var i = 0; i < cart.length; i++) {
                                      var item = cart[i];
                                      productsInCart
                                          .add(item['productID'].toString());
                                    }

                                    if (productsInCart.contains(
                                        filterList[index].documentID)) {
                                      for (var j = 0; j < cart.length; j++) {
                                        var it = cart[j];
                                        if (it['productID'] ==
                                            filterList[index].documentID) {
                                          it['quantity'] = it['quantity'] + 1;
                                        }
                                      }
                                    } else {
                                      cart.add({
                                        'user_uid':
                                            widget.userDetails.documentID,
                                        'product': filterList[index].data,
                                        'timestamp': DateTime.now()
                                            .millisecondsSinceEpoch,
                                        'cost': filterList[index]
                                            .data['item_price'],
                                        'quantity': 1,
                                        'productID':
                                            filterList[index].documentID
                                      });
                                    }
                                  }
                                  Firestore.instance
                                      .collection('cart')
                                      .document(widget.userDetails.documentID)
                                      .setData({'cart': cart}, merge: true);

                                  _showInfoDialog(
                                      context, "Item has been added to cart.");
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
          }
        },
      ),
    );
  }

  Widget productGridView(String category) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: category == "All Products"
            ? Firestore.instance
                .collection('products')
                .where('shop_uid', isEqualTo: widget.shopDetails.documentID)
                .snapshots()
            : Firestore.instance
                .collection('products')
                .where('shop_uid', isEqualTo: widget.shopDetails.documentID)
                .where('item_category', isEqualTo: category)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                ),
              );
            default:
              List<DocumentSnapshot> filterList = snapshot.data.documents;
              if (filterList.length < 1) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 96.0, 16.0, 16.0),
                    child: Text(
                        "There are no products in this category available."),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                  child: ResponsiveGridList(
                    desiredItemWidth: 150,
                    minSpacing: 8,
                    children: filterList
                        .map(
                          (item) => Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  ),
                                  child: Image.network(
                                    item.data['img_url'],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      8.0, 12.0, 8.0, 4.0),
                                  child: Text(
                                    item.data['item_name'] + " (" + item.data['item_quantity'] + ")",
                                    style: TextStyle(fontSize: 16.0),
                                    maxLines: 3,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Text(
                                    "₹" + item.data['item_price'],
                                    style: TextStyle(fontSize: 16.0),
                                    maxLines: 2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                                  child: OutlineButton(
                                    // icon: Icon(Icons.add_shopping_cart),
                                    shape: StadiumBorder(),
                                    borderSide: BorderSide(
                                      color: Colors.orange,
                                    ),
                                    child: Text(
                                      "Add to Cart",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () {
                                      Firestore.instance
                                          .collection('cart')
                                          .document(
                                              widget.userDetails.documentID)
                                          .get()
                                          .then((document) {
                                        List<dynamic> cart;
                                        if (document.exists) {
                                          cart = document.data['cart'];
                                        } else {
                                          cart = [];
                                        }

                                        if (cart.length < 1) {
                                          cart.add({
                                            'user_uid':
                                                widget.userDetails.documentID,
                                            'product': item.data,
                                            'timestamp': DateTime.now()
                                                .millisecondsSinceEpoch,
                                            'cost': item.data['item_price'],
                                            'quantity': 1,
                                            'productID': item.documentID
                                          });
                                        } else {
                                          List<String> productsInCart = [];

                                          for (var i = 0;
                                              i < cart.length;
                                              i++) {
                                            var item = cart[i];
                                            productsInCart.add(
                                                item['productID'].toString());
                                          }

                                          if (productsInCart
                                              .contains(item.documentID)) {
                                            for (var j = 0;
                                                j < cart.length;
                                                j++) {
                                              var it = cart[j];
                                              if (it['productID'] ==
                                                  item.documentID) {
                                                it['quantity'] =
                                                    it['quantity'] + 1;
                                              }
                                            }
                                          } else {
                                            cart.add({
                                              'user_uid':
                                                  widget.userDetails.documentID,
                                              'product': item.data,
                                              'timestamp': DateTime.now()
                                                  .millisecondsSinceEpoch,
                                              'cost': item.data['item_price'],
                                              'quantity': 1,
                                              'productID': item.documentID
                                            });
                                          }
                                        }
                                        Firestore.instance
                                            .collection('cart')
                                            .document(
                                                widget.userDetails.documentID)
                                            .setData({'cart': cart},
                                                merge: true);

                                        _showInfoDialog(context,
                                            "Item has been added to cart.");
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }
          }
        },
      ),
    );
  }

  Widget addressView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
      child: Badge(
        position: BadgePosition.bottomLeft(bottom: 150),
        badgeColor: Theme.of(context).accentColor,
        badgeContent: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(Icons.add_location, color: Colors.white),
        ),
        child: SizedBox(
          height: 64,
          child: Card(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
            child: ListTile(
              title: Text(
                widget.shopDetails.data['shop_address'],
                style: TextStyle(fontFamily: AppFontFamilies.mainFont),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () {
                  MapUtils.openMap(widget.shopDetails['shop_lat'],
                      widget.shopDetails['shop_lon']);
                },
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget cartIcon(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('cart')
            .document(widget.userDetails.documentID)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Badge(
              badgeContent: Text("0",
                  style: TextStyle(
                      fontFamily: AppFontFamilies.mainFont,
                      color: Colors.white)),
              child: new IconButton(
                icon: Icon(Icons.shopping_cart,
                    color: Theme.of(context).accentColor),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CartPage(
                                userData: widget.userDetails,
                              )));
                },
              ),
            );
          }
          var userDocument = snapshot.data['cart'];
          return new Badge(
            position: BadgePosition.topRight(right: 4, top: 4),
            badgeContent: Text(userDocument.length.toString(),
                style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont, color: Colors.white)),
            child: new IconButton(
              icon: Icon(Icons.shopping_cart,
                  color: Theme.of(context).accentColor),
              onPressed: () async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CartPage(
                              userData: widget.userDetails,
                            )));
              },
            ),
          );
        });
  }

  List<String> categoriesByIndustry(String industry) {
    if (industry == 'Agriculure') {
      return ['Pesticides', 'Grains', 'Seeds', 'Other'];
    } else if (industry == 'Consurmer durables') {
      return ['Other'];
    } else if (industry == 'Education') {
      return ['Other'];
    } else if (industry == 'Engineering and capital goods') {
      return ['Electronic Parts', 'Electronic gadgets', 'Other'];
    } else if (industry == 'Gems and Jwellery') {
      return ['Ring', 'Necklace', 'Pendant', 'Gold', 'Silver', 'Other'];
    } else if (industry == 'Grocery') {
      return [
        'Beverages',
        'Bread/Bakery',
        'Canned/Jarred Goods',
        'Dairy',
        'Baking Goods',
        'Frozen Goods',
        'Snacks',
        'Spices',
        'Meat',
        'Milk Produce',
        'Grains',
        'Cleaners',
        'Paper Goods',
        'Personal Care',
        'Other'
      ];
    } else if (industry == 'Liquor') {
      return [
        'Whiskey',
        'Beer',
        'Brandy',
        'Vodka',
        'Rum',
        'Gin',
        'Tequila',
        'Other'
      ];
    } else if (industry == 'Manufacturing') {
      return ['Other'];
    } else if (industry == 'Oil and Gas') {
      return ['Petrol', 'Diesel', 'CNG', 'Other'];
    } else if (industry == 'Pharmaceuticals') {
      return ['General', 'Prescription', 'Other'];
    } else if (industry == 'Retail') {
      return [
        'Tshirts',
        'Pants',
        'Jeans',
        'Shirts',
        'Inners',
        'Jackets',
        'Accessories',
        'Socks and shoes',
        'Other'
      ];
    } else if (industry == 'Stationary') {
      return [
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
      return ['Other'];
    } else if (industry == 'Vegetables and Fruits') {
      return ['Vegetables', 'Fruits', 'Extras', 'Other'];
    } else {
      return ['Other'];
    }
  }

  getCategories() {
    categories = categoriesByIndustry(widget.shopDetails['industry']);
    categories.insert(0, "All Products");
  }

  Widget tabWidget(String category) {
    return SingleChildScrollView(
      // child: buildProductGrid(category),
      child: productGridView(category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      body: DefaultTabController(
        length: categories.length,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: Text(
                  widget.shopDetails['shop_name'],
                  style: TextStyle(color: Colors.black.withOpacity(0.5)),
                ),
                actions: [cartIcon(context), SizedBox(width: 10)],
                expandedHeight: 250.0,
                elevation: 0,
                floating: false,
                pinned: true,
                iconTheme: IconThemeData(color: Colors.orange),
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Container(
                    child: Text(
                      widget.shopDetails['shop_name'],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                          image: NetworkImage(
                              widget.shopDetails.data['shop_image']),
                          height: 250,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover),
                      Container(
                        height: 250,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      Positioned(
                        // top: 100.0,
                        // right: 100.0,
                        child: addressView(),
                      )
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverAppBarDelegate(
                  TabBar(
                      isScrollable: true,
                      indicatorColor: Theme.of(context).hintColor,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: categories
                          .map((category) => Tab(text: category))
                          .toList()),
                ),
              )
            ];
          },
          body: TabBarView(
            children:
                categories.map((category) => tabWidget(category)).toList(),
          ),
        ),
      ),
    );
  }
}
