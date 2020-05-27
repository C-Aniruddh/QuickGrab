import 'dart:async';
import 'dart:math';
import 'package:app/notificationHandler.dart';
import 'package:app/screens/cart/order_completed_page.dart';
import 'package:app/screens/home_page/shop_completed_orders.dart';
import 'package:app/screens/home_page/shop_pending_orders.dart';
import 'package:app/screens/home_page/shop_scheduled_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:device_id/device_id.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:jiffy/jiffy.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badges/badges.dart';
import 'package:app/screens/utils/order_data_table.dart';

import '../../fonts.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}

class OrderSchedulePage extends StatefulWidget {
  OrderSchedulePage({Key key, this.userData, this.shopDetails, this.items})
      : super(key: key);

  final DocumentSnapshot userData;
  final DocumentSnapshot shopDetails;
  var items;

  @override
  _OrderSchedulePageState createState() => _OrderSchedulePageState();
}

class _OrderSchedulePageState extends State<OrderSchedulePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  int currentPage = 0;
  String currentTitle = "Home";
  String userUID;

  bool userLoaded = false;
  bool timeSlotsLoaded = false;

  String profilePicUrl;
  String userEmail;

  DocumentSnapshot userData;

  String appId = "ca-app-pub-7265536593732931~3339675400";

  GeoHasher gH = GeoHasher();

  String token;


  List showScheduledForShop = [];

  List<String> subtitleSlots = [];

  List selectedSlots = [];

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController _dataController = TextEditingController();


  setupAds() async {
    String device_id = await DeviceId.getID;
  }

  Future<void> _signOut() async {
    try {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  String getCity(String address) {
    List<String> elements = address.split(',');
    String city = elements[elements.length - 3];
    return city.trim();
  }

  getIntervals(String st, String et) {
    List<String> start = st.split(':');
    List<String> end = et.split(':');

    int startHour = int.parse(start[0]);
    int startMinute = int.parse(start[1]);
    int endHour = int.parse(end[0]);
    int endMinute = int.parse(end[1]);

    Jiffy startTime = Jiffy({"hour": startHour, "minute": startMinute});

    Jiffy endTime = Jiffy({"hour": endHour, "minute": endMinute});

    int currentHour = 0;
    int currentMinute = 0;

    List<String> slots = [];
    Jiffy previousTime = startTime;

    while (previousTime.isBefore(endTime)) {
      Jiffy tempTime = new Jiffy(previousTime);
      Jiffy newTime = Jiffy(tempTime.add(duration: Duration(minutes: 30)));
      currentHour = newTime.hour;
      currentMinute = newTime.minute;
      slots.add(previousTime.format("HH:mm") + "--" + newTime.format("HH:mm"));
      previousTime = newTime;
    }
    // print(slots);
    return slots;
  }

  List<String> getGeneralTimeSlots(DocumentSnapshot shopData) {
    if (shopData.data['start_time'] == null || shopData.data['end_time'] == null){
      String startTime = "08:00";
      String endTime = "21:00";
      return getIntervals(startTime, endTime);
    } else {
      String startTime = shopData.data['start_time'];
      String endTime = shopData.data['end_time'];
      return getIntervals(startTime, endTime);
    }
  }

  List<String> getStartTimes(List<String> timeSlots){
    List<String> startTimesAll = [];
    for(var i = 0; i < timeSlots.length; i++){
      String startTime = timeSlots[i].split('--')[0];
      startTimesAll.add(startTime);
    }
    return startTimesAll;
  }

  String getStartTime(String timeSlot){
    String startTime = timeSlot.split('--')[0];
    return startTime;
  }

  String getEndTime(String timeSlot){
    String endTime = timeSlot.split('--')[1];
    return endTime;
  }

  int countOccurrencesUsingWhereMethod(List<String> list, String element) {
    if (list == null || list.isEmpty) {
      return 0;
    }
    var foundElements = list.where((e) => e == element);
    return foundElements.length;
  }


  getSlots(List<DocumentSnapshot> shopScheduled, List<String> shopTimeLimits, DocumentSnapshot shopData){
    List<String> startTimes = [];
    for (var i=0; i<shopScheduled.length; i++){
      startTimes.add(shopScheduled[i].data['appointment_start']);
    }

    List slotData = [];

    List<String> remaningSlots = [];
    List<String> allStartTimes = getStartTimes(shopTimeLimits);

    /*for (var i = 0; i < allStartTimes.length; i++){
      if (startTimes.contains(allStartTimes[i])){
        if (shopData.data['limit'] - countOccurrencesUsingWhereMethod(startTimes, allStartTimes[i]) > 0) {
          slotData.add({'start_time': });
          remaningSlots.add(shopTimeLimits[i] + "-- Remaining Slots (" + (widget.shopData.data['limit'] - countOccurrencesUsingWhereMethod(startTimes, allStartTimes[i])).toString() + ")");
        }
      } else {
        remaningSlots.add(shopTimeLimits[i] + "-- Remaining Slots (" + widget.shopData.data['limit'].toString() + ")");
      }
    } */

    for (var i = 0; i <allStartTimes.length; i++){
      if(startTimes.contains(allStartTimes[i])){
        if (shopData['limits'] - countOccurrencesUsingWhereMethod(startTimes, allStartTimes[i]) > 0){
          slotData.add({'shop_name': shopData.data['shop_name'], 'start_time': getStartTime(shopTimeLimits[i]),
            'end_time': getEndTime(shopTimeLimits[i]), 'remaning_slots': shopData.data['limit'] - countOccurrencesUsingWhereMethod(startTimes, allStartTimes[i])});
        }
      } else {
        slotData.add({'shop_name': shopData.data['shop_name'], 'start_time': getStartTime(shopTimeLimits[i]),
          'end_time': getEndTime(shopTimeLimits[i]), 'remaning_slots': shopData.data['limit']});
      }
    }
    return slotData;
  }

  getShopSubtitle(String shop_uid){
    for (var i = 0; i < selectedSlots.length; i++){
      var slot = selectedSlots[i];
      if (slot['shop_uid'] == shop_uid){
        String time = slot['start_time'] + " - " + slot['end_time'];
        return time;
      }
    }
    return "Select time slot";
  }

  addIfNotPresent(String shop_uid, String startTime, String endTime){
    bool found = false;
    for (var i =0; i<selectedSlots.length; i++){
      var slot = selectedSlots[i];
      if (slot['shop_uid'] == shop_uid){
        found = true;
        selectedSlots[i] = {'start_time': startTime, 'end_time': endTime, 'shop_uid': shop_uid};
      }
    }
    if (found == false){
      selectedSlots.add({'start_time': startTime, 'end_time': endTime, 'shop_uid': shop_uid});
    }
  }

  singleShop(shopSlots, shopData, int index){
    return InkWell(
      onTap: (){
        List<String> labels = [];
        for (var i = 0; i < shopSlots.length; i++){
          labels.add(shopSlots[i]['start_time'] + " - " + shopSlots[i]['end_time'] + " - (Remaining slots : " + shopSlots[i]['remaning_slots'].toString() + ")");
        }
        showCupertinoModalBottomSheet(
          expand: false,
          context: context,
          builder: (context, scrollController) => Material(
            child: SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: SingleChildScrollView(
                  child: RadioButtonGroup(
                    labels: labels,
                    onSelected: (String selected) {
                      String reformat = selected.replaceAll(' - ', '--');
                      String startTime = getStartTime(reformat);
                      String endTime = getEndTime(reformat);
                      setState(() {
                        addIfNotPresent(shopData.documentID, startTime, endTime);
                        // selectedSlots.add({'start_time': startTime, 'end_time': endTime, 'shop_uid': shopData.documentID});
                        subtitleSlots[index] = startTime + " - " + endTime;
                      });
                      print(selectedSlots);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(title: Text(shopData.data['shop_name']),
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.alarm, color: Colors.blueGrey,),
                ],
              ),
              subtitle: Text(subtitleSlots[index]),
            ),
          ),
        ),
      ),
    );
  }

  getShops() async {
    List<String> shops = [];
    for (var i = 0; i < widget.items.length; i++) {
      var item = widget.items[i];
      String shop_uid = item['product']['shop_uid'];
      if (!shops.contains(shop_uid)) {
        shops.add(shop_uid);
        subtitleSlots.add("Select time slot");
      }
    }

    print(shops);
    List showSch = [];

    for (var i = 0; i < shops.length; i++){
      Firestore.instance.collection('shops')
              .document(shops[i])
              .get().then((shopData) {
                  List<String> shopTimeSlots = getGeneralTimeSlots(shopData);
                  print(shopTimeSlots);
                  Firestore.instance.collection('appointments')
                      .where('target_shop', isEqualTo: shops[i])
                      .where('appointment_status', isEqualTo: "scheduled")
                      .getDocuments()
                      .then((docs){
                    var shopSlots = getSlots(docs.documents, shopTimeSlots, shopData);
                    showSch.add({'shopData': shopData, 'shopSlots': shopSlots});
                    setState(() {
                      showScheduledForShop = showSch;
                    });
                  });
      });
    }

    setState(() {
      showScheduledForShop = showSch;
    });
  }

  getStartAndEndTimeByShopUID(String shop_uid){
    for (var i = 0; i < selectedSlots.length; i++){
      if(selectedSlots[i]['shop_uid'] == shop_uid){
        return selectedSlots[i];
      }
    }
    return null;
  }

  Widget buildHomePayment() {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Schedule your order",
                  style:
                      TextStyle(fontSize: 18, fontFamily: AppFontFamilies.mainFont)),
            ),
            showScheduledForShop.length == 0 ?
                Container()
            : ListView.builder(
              shrinkWrap: true,
              itemCount: showScheduledForShop.length,
              itemBuilder: (BuildContext cxtx, int index){
                return singleShop(showScheduledForShop[index]['shopSlots'],
                showScheduledForShop[index]['shopData'], index);
              },
            )
            // orderConfirmView(),

    ]));
  }

  placeOrder() async {
    var rng = new Random();
    var now = new DateTime.now();

    List<DocumentReference> appointments_ref = [];
    List<DocumentSnapshot> appointments = [];

    if (selectedSlots.length == showScheduledForShop.length){
      _showInfoDialog(
          context, "Your order is being placed");
      List<String> shops = [];
      for (var i = 0; i < widget.items.length; i++) {
        var item = widget.items[i];
        String shop_uid = item['product']['shop_uid'];
        if (!shops.contains(shop_uid)) {
          shops.add(shop_uid);
        }
      }

      for (var i = 0; i < shops.length; i++) {
        var orderItems = [];
        for (var j = 0; j < widget.items.length; j++) {
          var item = widget.items[j];
          String shop_uid = item['product']['shop_uid'];
          if (shop_uid == shops[i]) {
            orderItems.add(item);
          }
        }

        await Firestore.instance
            .collection('shops')
            .document(shops[i])
            .get()
            .then((shopDoc) async {
          var slotDetails = getStartAndEndTimeByShopUID(shopDoc.documentID);
          String startTime = slotDetails['start_time'];
          String endTime = slotDetails['end_time'];
          DateTime selectedDate = DateTime.now();
          String formattedDate =
              "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
          await Firestore.instance
              .collection('appointments')
              .add({
            'timestamp': now,
            'items': orderItems,
            'target_shop': shopDoc.data['uid'],
            'shopper_uid': widget.userData['uid'],
            'shopper_name': widget.userData['name'],
            'shop_name': shopDoc.data['shop_name'],
            'shop_geohash': shopDoc.data['shop_geohash'],
            'appointment_status': 'scheduled',
            'appointment_start': startTime,
            'appointment_end': endTime,
            'appointment_date': formattedDate,
            'otp': (rng.nextInt(9000) + 999).toString()
          }).then((value) async {
            appointments_ref.add(
              value
            );
            String title = "New appointment request";
            String body = widget.userData['name'] +
                " has requested an appointment.";
            await Firestore.instance
                .collection('notifications')
                .add({
              'sender_type': "users",
              'receiver_uid': shopDoc.data['uid'],
              'title': title,
              'body': body,
              'read': false,
              'timestamp': DateTime.now()
            });

            await Firestore.instance
                .collection('cart')
                .document(widget.userData.documentID)
                .setData({'cart': []});

            for (var a = 0; a < appointments_ref.length; a ++){
              await Firestore.instance
                  .collection('appointments')
                  .document(appointments_ref[i].documentID)
                  .get()
                  .then((doc){
                 appointments.add(doc);
              });
            }
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => OrderCompletedPage(appointments: appointments,)), (route) => false);

          });
        });
    }
    } else {
        _showInfoDialog(context, "Please select time slot for each store.");
    }
  }

  @override
  void initState() {
    // FirebaseAdMob.instance.initialize(appId: appId);
    getShops();
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: Icon(Icons.close),
            color: Colors.black,
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text("Schedule order",
              style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont, color: Colors.black)),
        ),
      ),
      body: buildHomePayment(),
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
                  )),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Container()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: RaisedButton(
                        color: Theme.of(context).accentColor,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0),
                        ),
                        onPressed: () async {
                          placeOrder();
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPaymentPage(items: cartItems)));
                        },
                        child: ListTile(
                            title: Text("Complete Order",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: AppFontFamilies.mainFont)),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ))),
                  )
                ],
              ),
            )),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
