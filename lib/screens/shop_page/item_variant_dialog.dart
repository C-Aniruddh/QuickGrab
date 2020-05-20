import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemVariantDialog extends StatefulWidget {
  final String industry;

  ItemVariantDialog({Key key, this.industry});
  @override
  State createState() => new _ItemVariantDialogState();
}

class _ItemVariantDialogState extends State<ItemVariantDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedUnit;

  List<String> units = ["Kg", "g", "mL", "L", "pack", "units"];

  TextEditingController sizeController = new TextEditingController();
  TextEditingController quantityController = new TextEditingController();
  TextEditingController priceController = new TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Widget customTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 44.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(
              child: new IconButton(
                  icon: Icon(
                    iconData,
                    size: 20.0,
                  ),
                  onPressed: null),
            ),
            new Flexible(
              child: new TextFormField(
                enabled: enabled,
                keyboardType: keyType,
                decoration: new InputDecoration.collapsed(
                  hintText: hint,
                ),
                controller: textEditingController,
                validator: (value) {
                  if (validate) {
                    if (value.isEmpty) {
                      return 'This field should not be empty';
                    } else {
                      return null;
                    }
                  } else {
                    return null;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sizeTextField(IconData iconData, String hint,
      TextEditingController textEditingController,
      {enabled = true, keyType = TextInputType.text, validate = true}) {
    return Container(
      height: 44.0,
      margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: new Container(
        padding: const EdgeInsets.only(left: 8, right: 5),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
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
                  icon: Icon(
                    iconData,
                    size: 20.0,
                  ),
                  onPressed: null),
            ),
            new Flexible(
              child: new TextFormField(
                enabled: enabled,
                keyboardType: keyType,
                decoration: new InputDecoration.collapsed(
                  hintText: hint,
                ),
                controller: textEditingController,
                validator: (value) {
                  if (validate) {
                    if (value.isEmpty) {
                      return 'This field should not be empty';
                    } else {
                      return null;
                    }
                  } else {
                    return null;
                  }
                },
              ),
            ),
            buildDropDown(),
          ],
        ),
      ),
    );
  }

  Widget buildButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: RaisedButton(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(color: Colors.orangeAccent)),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              if (_selectedUnit != null) {
                if (widget.industry == "Liquor") {
                  _selectedUnit = "mL";
                }
                List itemVariant = [
                  sizeController.text,
                  _selectedUnit,
                  quantityController.text,
                  priceController.text
                ];
                Navigator.pop(context, itemVariant);
              }
            }
          },
          color: Colors.orangeAccent,
          textColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Add variant",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropDown() {
    return DropdownButtonHideUnderline(
      child: new DropdownButton(
        iconDisabledColor: Colors.grey,
        iconEnabledColor: Colors.grey,
        hint: Text(
          "Unit",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        value: _selectedUnit,
        isDense: true,
        onChanged: (String newValue) {
          setState(() {
            _selectedUnit = newValue;
          });
        },
        items: units.map((String value) {
          return new DropdownMenuItem(
            value: value,
            child: new Text(
              value,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SafeArea(
            child: Row(
              children: [
                widget.industry == "Liquor"
                    ? customTextField(
                        Icons.format_list_numbered_rtl,
                        "Size",
                        sizeController,
                        keyType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      )
                    : sizeTextField(
                        Icons.format_list_numbered_rtl,
                        "Size",
                        sizeController,
                        keyType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
              ],
            ),
          ),
          _selectedUnit == null
              ? Text(
                  "Please select a unit along with the size.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                )
              : Container(),
          customTextField(
            Icons.local_grocery_store,
            "Quantity",
            quantityController,
            keyType: TextInputType.number,
          ),
          customTextField(
            Icons.local_offer,
            "Price",
            priceController,
            keyType: TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          buildButton(),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return new SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          new Text("Add a variant"),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      children: <Widget>[
        buildBody(),
      ],
    );
  }
}
