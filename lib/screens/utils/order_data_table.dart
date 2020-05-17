import 'package:app/fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderTable extends StatelessWidget {
  final List<dynamic> document;
  final String total;
  OrderTable({
    Key key,
    this.document,
    this.total,
  }) : super(key: key);

  rowContent(invoiceData, total, BuildContext context) {
    List<DataRow> rows = [];
    int totalQty = 0;

    for (dynamic content in invoiceData) {
      rows.add(
        DataRow(
          cells: [
            DataCell(
              Container(
                width: MediaQuery.of(context).size.width * 0.25,
                child: Text(
                  content['product']['item_name'].toString(),
                  style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                child: Text(
                  content['quantity'].toString(),
                  style: TextStyle(
                    fontFamily: AppFontFamilies.mainFont,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                content['cost'].toString(),
                style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
      totalQty = totalQty + int.parse(content['quantity'].toString());
    }
    rows.add(
      DataRow(
        cells: [
          DataCell(
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              child: Text(
                "Total",
                style: TextStyle(
                  fontFamily: AppFontFamilies.mainFont,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              totalQty.toString(),
              style: TextStyle(
                fontFamily: AppFontFamilies.mainFont,
                color: Colors.black87,
              ),
            ),
          ),
          DataCell(
            Text(
              total.toString(),
              style: TextStyle(
                fontFamily: AppFontFamilies.mainFont,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
    return rows;
  }

  Widget orderCardTable(var document, String total, BuildContext context) {
    return DataTable(
      dividerThickness: 0.0,
      columns: [
        DataColumn(
          label: Text(
            "Item",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: false,
        ),
        DataColumn(
          label: Text(
            "Quantity",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            "Price",
            style: TextStyle(
              fontFamily: AppFontFamilies.mainFont,
              color: Colors.black87,
            ),
          ),
          numeric: false,
        ),
      ],
      rows: rowContent(document, total, context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return orderCardTable(document, total, context);
  }
}
