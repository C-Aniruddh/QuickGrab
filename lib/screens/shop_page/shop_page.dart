import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:app/screens/cart/cart_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app/screens/home_page/user_home_page.dart';

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

  final TextEditingController _textEditingController = new TextEditingController();

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
      builder: (ctxt){
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("Request an appointment"),
                TextFormField(
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'What do you want to buy?'),
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
                onPressed: () async{
                  var rng = new Random();
                  var now = new DateTime.now();
                  await Firestore.instance.collection('appointments')
                      .add({'timestamp': now,
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
                  }).then((value) async{
                    String title = "New appointment request";
                    String body = widget.userDetails['name'] + " has requested an appointment.";
                    await Firestore.instance.collection('notifications')
                        .add({'sender_type': "users",
                      'receiver_uid': widget.shopDetails['uid'],
                      'title': title,
                      'body': body,
                    });
                  });
                  Navigator.pop(context);
                  _showInformationDialog(context, "Your appointment was successfully requested");
                })
          ],
        );
      },
    );
  }

  Widget productView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("Popular Products",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: buildProductGrid(),
          )
        ]);
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

  Widget buildProductGrid() {

    return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('products')
              .where(FieldPath.documentId,
                whereIn: widget.shopDetails.data['inventory'])
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
                    child: Text("There are no shops around you."),
                  );
                } else {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: GridView.builder(
                      itemCount: filterList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: (3 / 4)),
                      itemBuilder: (BuildContext context, int index) {
                        return InkWell(
                          onTap: (){
                          },
                          child: Card(
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
                                          Firestore.instance.collection('cart')
                                              .document(widget.userDetails.documentID)
                                              .get()
                                              .then((document) {
                                                List<dynamic> cart;
                                                if (document.exists){
                                                  print("Does exist");
                                                  cart = document.data['cart'];
                                                } else {
                                                  print("Created");
                                                  cart = [];
                                                }
                                                print(cart);
                                                cart.add(
                                                  {'user_uid': widget.userDetails.documentID,
                                                    'product': filterList[index].data,
                                                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                                                    'cost': filterList[index].data['item_price'],
                                                    'quantity': 1,
                                                    'productID': filterList[index].documentID
                                                  }
                                                );
                                                print(cart);
                                                print("Adding");
                                                Firestore.instance.collection('cart')
                                                  .document(widget.userDetails.documentID)
                                                .setData({'cart': cart}, merge: true);

                                                _showInfoDialog(context, "Item has been added to cart.");
                                          });
                                         // Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScheduledOrders(userData: userData,)));
                                        },
                                        child: Icon(Icons.add_shopping_cart, color: Colors.white)
                                    ),
                                  ),

                                ],
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
        ));
  }


  Widget buildShop() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children : [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text("Shop on Map",
                style: TextStyle(
                    fontSize: 20, fontFamily: AppFontFamilies.mainFont)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Card(
              child: Container(
                child: SizedBox(
                    height: 250,
                    width: MediaQuery.of(context).size.width,
                    child: mapLoaded
                        ? GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _kGooglePlex,
                      markers: Set<Marker>.of(markers.values),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    )
                        : Container()),
              ),
            ),
          ),
          productView()
        ]
      )
    );
  }


  Widget buildOldShop() {
    return Container(
      constraints: BoxConstraints.expand(),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              constraints: BoxConstraints.expand(),
              child:
              SizedBox(
                  height: MediaQuery.of(context).size.height * 0.50,
                  width: MediaQuery.of(context).size.width,
                  child: mapLoaded
                      ? GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kGooglePlex,
                    markers: Set<Marker>.of(markers.values),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  )
                      : Container()),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.bottomCenter,
              constraints: BoxConstraints.expand(),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListTile(
                                        title: Text("Address"),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).accentColor,
                                          child: Text("A"),
                                        ),
                                        subtitle: Text(widget.shopDetails['shop_address']),
                                        trailing: IconButton(
                                          icon: Icon(Icons.map),
                                          onPressed: () {
                                            print("Open");
                                            MapUtils.openMap(widget.shopDetails['shop_lat'],
                                                widget.shopDetails['shop_lon']);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListTile(
                                        title: Text("Contact Owner"),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).accentColor,
                                          child: Text("C"),
                                        ),
                                        subtitle: Text(
                                            widget.shopDetails['shop_contact_name'] +
                                                " (" +
                                                widget.shopDetails['phone_number'] +
                                                ")"),
                                        trailing: IconButton(
                                          icon: Icon(Icons.call),
                                          onPressed: () {
                                            print("Open");
                                            // MapUtils.openMap(widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListTile(
                                        title: Text("User Limit (Every 10 minutes)"),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).accentColor,
                                          child: Text("L"),
                                        ),
                                        subtitle:
                                        Text(widget.shopDetails['limit'].toString()),
                                        trailing: IconButton(
                                          icon: Icon(Icons.info),
                                          onPressed: () {
                                            print("Open");
                                            // MapUtils.openMap(widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              ))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget oldAppbar(){
    return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text(widget.shopDetails['shop_name'],
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Theme.of(context).accentColor),
            onPressed: () async {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => CartPage()));
            },
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            actions: [
              widget.userDetails['favorites'].contains(widget.shopDetails.documentID) ?
                    IconButton(icon: Icon(Icons.star), color: Theme.of(context).accentColor,
                    onPressed: () {
                      List<dynamic> fav = widget.userDetails['favorites'];
                      setState(() {
                        fav.remove(widget.shopDetails.documentID);
                        Firestore.instance.collection('users')
                            .document(widget.userDetails.documentID)
                            .updateData({'favorites': fav});
                      });

                    },)
                  : IconButton(icon: Icon(Icons.star_border),
                onPressed: () {
                  List<dynamic> fav = widget.userDetails['favorites'];
                  setState(() {
                    fav.add(widget.shopDetails.documentID);
                    Firestore.instance.collection('users')
                        .document(widget.userDetails.documentID)
                        .updateData({'favorites': fav});
                  });
                },)
            ],
            pinned: false,
            floating: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.black),
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.shopDetails['shop_name'], style: TextStyle(fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
              background: Hero(tag: widget.shopDetails.documentID,
              child: Image.network(widget.shopDetails.data['shop_image'], fit: BoxFit.cover)),
            ),
          ),
          SliverToBoxAdapter(
            child: buildShop()
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog();
        },
        tooltip: 'Make an appointment',
        child: Icon(Icons.add),
      ),
    );
  }
}
