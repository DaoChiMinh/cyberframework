import 'package:cyberframework/cyberframework.dart';

abstract class Formchklist extends CyberForm {
  EdgeInsets get saveButtonPadding =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);
  bool get showSearchBox => false;
  int get initialTabIndex => 0;

  CyberDataTable? _dtList;
  CyberDataTable? _dtMaster;
  CyberDataTable? _dttag;
  String? _ma_tag;

  @override
  Future<void> onLoadData() async {
    _ma_tag = "";
    var (ds1, isOk) = await context.callApiAndCheck(
      functionName: cp_name,
      parameter: strparameter,
    );
    if (isOk) {
      _dtList = ds1![0];
      _dtMaster = ds1![1];
      _dttag = ds1![2];

      this.title = _dtMaster![0]["title"] ?? this.title;
    }

    return super.onLoadData();
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
              label: row['ten_tag'] ?? '',
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
          itemBuilder: buildItemList,
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
    close();
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
