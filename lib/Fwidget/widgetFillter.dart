import 'package:cyberframework/cyberframework.dart';

Widget widgetFillterEdit(CyberDataTable dtHeader, CyberDataRow row) {
  Map<int, List<Widget>> rowGroups = {};
  for (CyberDataRow dr in dtHeader.rows) {
    int rowId = dr.getInt("row_id");
    String field_type = (dr["Field_Type"] ?? "").toLowerCase();

    rowGroups.putIfAbsent(rowId, () => []);

    Widget? _child;
    switch (field_type) {
      case "n":
        _child = CyberNumeric(
          label: dr["Field_Head1"],
          hint: dr["Field_Head1"],
          text: row.bind(dr["field_name"]),
          enabled: dr.getBool("is_ReadOnly"),
        );
        break;
      case "d":
        _child = CyberDate(
          label: dr["Field_Head1"],
          hint: dr["Field_Head1"],
          text: row.bind(dr["field_name"]),
          enabled: dr.getBool("is_ReadOnly"),
        );
        break;
      case "L":
        _child = CyberLookup(
          label: dr["Field_Head1"],
          hint: dr["Field_Head1"],
          text: row.bind(dr["field_name"]),
          display: row.bind(dr["DisPlay"]),
          tbName: dr["Tb_LookUp"],
          displayField: dr["DisPlay_LookUp"],
          displayValue: dr["Value_lookUp"],
          strFilter: dr["strFillterLookup"],
          allowClear: false,
          enabled: dr.getBool("is_ReadOnly"),
        );
        break;
      case "C":
        _child = CyberText(
          label: dr["Field_Head1"],
          hint: dr["Field_Head1"],
          text: row.bind(dr["field_name"]),
          enabled: dr.getBool("is_ReadOnly"),
        );
        break;
      default:
        _child = CyberLabel(text: row.bind(dr["field_name"]));
        break;
    }
    rowGroups[rowId]!.add(
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _child,
        ),
      ),
    );
  }
  return Column(
    children: rowGroups.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(children: e.value),
          ),
        )
        .toList(),
  );
}

Widget widgetFillterView(CyberDataTable dtHeader, CyberDataRow row) {
  Map<int, List<Widget>> rowGroups = {};

  for (CyberDataRow dr in dtHeader.rows) {
    TextAlign textAlign = TextAlign.left;
    int rowId = dr.getInt("row_id");
    String field_type = (dr["Field_Type"] ?? "").toLowerCase();
    String strData = row[dr["Field_Name"]]?.toString() ?? "";
    int fieldWidth = dr.getInt("Field_width");

    rowGroups.putIfAbsent(rowId, () => []);

    if (field_type == "n") {
      textAlign = TextAlign.right;
      strData = row.toString2(dr["Field_Name"], dr["Format"] ?? "### ### ###");
    } else if (field_type == "d") {
      textAlign = TextAlign.center;
      strData = row.toString2(dr["Field_Name"], dr["Format"] ?? "dd/MM/yyyy");
    }

    Widget fieldWidget = Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${dr["Field_Head1"]}: ",
            style: const TextStyle(color: Colors.grey),
          ),
          Expanded(
            child: Text(
              strData,
              textAlign: textAlign,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );

    // Nếu Field_width = 0 thì dùng Expanded (tự động tràn)
    // Nếu Field_width > 0 thì dùng SizedBox với width cố định
    if (fieldWidth == 0) {
      rowGroups[rowId]!.add(Expanded(child: fieldWidget));
    } else {
      rowGroups[rowId]!.add(
        SizedBox(width: fieldWidth.toDouble(), child: fieldWidget),
      );
    }
  }

  // Xử lý mỗi row: nếu tất cả Field_width > 0 thì thêm Expanded ở giữa
  return Column(
    children: rowGroups.entries.map((e) {
      List<Widget> rowWidgets = e.value;

      // Kiểm tra xem có widget nào là Expanded không
      bool hasExpandedWidget = rowWidgets.any((widget) => widget is Expanded);

      // Nếu không có Expanded nào (tất cả đều có width cố định)
      // thì thêm Expanded() ở giữa để tràn đều
      if (!hasExpandedWidget && rowWidgets.isNotEmpty) {
        // Thêm Expanded vào giữa danh sách
        int middleIndex = (rowWidgets.length / 2).floor();
        rowWidgets = [
          ...rowWidgets.sublist(0, middleIndex),
          const Expanded(child: SizedBox()),
          ...rowWidgets.sublist(middleIndex),
        ];
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(children: rowWidgets),
      );
    }).toList(),
  );
}
