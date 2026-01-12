import 'package:cyberframework/cyberframework.dart';

abstract class CyberFormchklist extends CyberForm {
  EdgeInsets get saveButtonPadding =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);
  bool get showSearchBox => false;
  int get initialTabIndex => 0;

  CyberDataTable? _dtList;
  CyberDataTable? _dtMaster;
  CyberDataTable? _dttag;
  String? _ma_tag;
  List<int> selectedIndices = [];
  @override
  Future<void> onLoadData() async {
    _ma_tag = "";
    _dtList = await v_loadData(1, 20, "");

    return super.onLoadData();
  }

  Future<CyberDataTable> v_loadData(
    int pageIndex,
    int pageSize,
    String strSearch,
  ) async {
    String m_load = "1";
    if (pageIndex > 0) m_load = "0";
    List<String> _paras = strparameter.split("#");
    _paras[0] = m_load;
    _paras[1] = pageIndex.toString();
    _paras[3] = strSearch;
    _paras[7] = _ma_tag ?? "";
    String _strparameter = _paras.join("#");

    var (ds1, isOk) = await context.callApiAndCheck(
      functionName: cp_name,
      parameter: _strparameter,
      showLoading: true,
    );
    if (isOk) {
      if (m_load == "1") {
        selectedIndices.clear();
        _dtMaster = ds1![1];
        this.title = _dtMaster![0]["title"] ?? this.title;
      }
      _dttag = ds1![ds1!.tableCount - 1];
      return ds1![0]!;
    } else {
      return CyberDataTable(tableName: "data");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_dtList == null) {
      return SizedBox.shrink();
    }

    List<Widget> children = [];
    if (_dttag!.rowCount > 1) {
      children.add(
        CyberSwitchButton(
          options: List.generate(_dttag!.rowCount, (index) {
            var row = _dttag![_dttag!.rowCount - index - 1];
            return CyberSwitchOption(
              label: row['title'] ?? '',
              value: row['ma_tag'] ?? '',
            );
          }),
          initialIndex: initialTabIndex,
          onChanged: (index, value, option) {
            print('Selected: ${option.label}');
            _ma_tag = option.value;
          },
        ),
      );
    }

    children.add(buildHeader());
    children.add(
      Expanded(
        child: CyberListView(
          itemBuilder: (context, row, index) {
            return Padding(
              padding: EdgeInsets.all(1),

              child: Container(
                decoration: BoxDecoration(
                  border: selectedIndices.contains(index)
                      ? Border.all(color: textColorDefault!, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: buildItemList(context, row, index),
              ),
            );
          },
          onLoadData: v_loadData,
          onItemTap: (row, index) {
            print('Tapped item at index $index');
            if (selectedIndices.contains(index)) {
              selectedIndices.remove(index);
            } else {
              selectedIndices.add(index);
            }
            rebuild();
          },
          dataSource: _dtList,
          showSearchBox: showSearchBox,
        ),
      ),
    );

    children.add(buildFooter());
    children.add(
      Padding(
        padding: saveButtonPadding,
        child: CyberButton(
          label: setText("Xác nhận", "Confirm"),
          onClick: SaveData,
        ),
      ),
    );
    return Column(children: children);
  }

  @override
  // ignore: override_on_non_overriding_member
  Future<void> SaveData() async {
    var selectedRows = selectedIndices
        .map((index) => _dtList!.rows[index])
        .toList();
    close(result: selectedRows);
  }

  @override
  // ignore: override_on_non_overriding_member
  Widget buildHeader() {
    return SizedBox.shrink();
  }

  @override
  // ignore: override_on_non_overriding_member
  Widget buildFooter() {
    return SizedBox.shrink();
  }

  @override
  // ignore: override_on_non_overriding_member
  Widget buildItemList(BuildContext context, CyberDataRow row, int index) {
    return SizedBox.shrink();
  }
}
