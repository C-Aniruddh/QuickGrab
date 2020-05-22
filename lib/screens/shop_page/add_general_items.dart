import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class StandardInventory extends StatefulWidget {
  StandardInventory({Key key, this.industry, this.shopDetails}) : super(key: key);
  final String industry;
  final DocumentSnapshot shopDetails;

  @override
  _StandardInventoryState createState() => _StandardInventoryState();
}

class _StandardInventoryState extends State<StandardInventory> {
  DocumentSnapshot itemData;
  bool itemsLoaded = false;

  List<bool> isSelectedList;
  List<dynamic> items;
  var source;


  void setItemData() async {
    await Firestore.instance
        .collection('standard_inventory')
        .document(widget.industry)
        .get()
        .then((data) {
      itemData = data;
      items = itemData.data['items'];
      isSelectedList = new List<bool>.generate(itemData.data['items'].length, (i) => true);
      source = Source(itemData: items, isSelectedList: isSelectedList);
    });
    setState(() {
      itemsLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    setItemData();
  }

  Widget table() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 12.0),
      child: PaginatedDataTable(
        showCheckboxColumn: true,
        rowsPerPage: 5,
        header: Text("General Items List"),
        columns: <DataColumn>[
          DataColumn(
            label: Text(
              "Item Name",
              style: TextStyle(fontSize: 15.0),
            ),
          ),
          DataColumn(
            label: Text(
              "Quantity",
              style: TextStyle(fontSize: 15.0),
            ),
          ),
          DataColumn(
            label: Text(
              "Price",
              style: TextStyle(fontSize: 15.0),
            ),
          ),
        ],
        source: source,
      ),
    );
  }

  Widget tableView() {
    return Container(
        child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: SingleChildScrollView(
        child: table(),
      ),
    ));
  }

  Widget addView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 8.0),
          child: Text(
            "Select Items based on the title, quantity and price as given in the table above.",
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
          child: Text(
            "Add the selected items to your inventory from our pre-defined list of products.\nIf some items are not available in your store, then de-select them",
            maxLines: 4,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.0,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Center(
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(color: Colors.orangeAccent)),
              onPressed: () {
                // TODO: Add logic
                var batch = Firestore.instance.batch();
                var uuid = Uuid();
                int added = 0;
                List<bool> selectedList = source.returnBooleanList();
                for (var i = 0; i < selectedList.length; i++){
                  var items = itemData.data['items'];
                  var item = items[i];
                  if (selectedList[i]){
                    var product = {'shop_industry': widget.industry, 'shop_uid': widget.shopDetails.documentID,
                        'img_url': item['img_url'], 'item_category': item['item_category'], 'item_price': item['item_price'],
                        'item_description': item['item_description'], 'item_quantity': item['item_quantity'], 'item_name': item['item_name']};
                    String document_id = uuid.v4();
                    if (added < 500){
                      added = added + 1;
                      batch.setData(Firestore.instance.collection('products')
                          .document(document_id), product);
                    }
                  }
                }
                batch.commit();
              },
              color: Colors.orangeAccent,
              textColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Add to Inventory",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tableView(),
        addView(),
      ],
    );
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
          },
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text(
            "General Items",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
      body: itemsLoaded
          ? SingleChildScrollView(child: buildBody())
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class Source extends DataTableSource {
  final List<dynamic> itemData;
  List<bool> isSelectedList;
  
  Source({this.itemData, this.isSelectedList});

  @override
  DataRow getRow(int index) {
    var item = itemData[index];
    return DataRow.byIndex(
      index: index,
      selected: isSelectedList[index],
      cells: [
        DataCell(
          Text(item['item_name'].toString()),
        ),
        DataCell(
          Text(item['item_quantity'].toString()),
        ),
        DataCell(
          Text(item['item_price'].toString()),
        ),
      ],
      onSelectChanged: (bool value) {
          if (isSelectedList[index] != value) {
            isSelectedList[index] = value;
            notifyListeners();
          }
      },
    );
  }

  @override
  int get rowCount => itemData.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount {
    int count = 0;
    for (bool value in isSelectedList) {
      if (value == true) {
        count = count + 1;
      }
    }
    return count;
  }

  List<bool> returnBooleanList() {
    return isSelectedList;
  }
}
