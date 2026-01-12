import 'package:cyberframework/cyberframework.dart';

abstract class Formchklist extends CyberForm {
  EdgeInsets get saveButtonPadding =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);
  bool get showSearchBox => false;
  int get initialTabIndex => 0;

  CyberDataTable? _dtList;
  CyberDataTable? _dtMaster;
  CyberDataTable? _dttag;
  @override
  Future<void> onLoadData() async {
    var (ds1, isOk) = await context.callApiAndCheck(
      functionName: cp_name,
      parameter: strparameter,
    );
    if (isOk) {
      _dtList = ds1![0];
      _dtMaster = ds1![1];
      _dttag = ds1![2];
    }

    return super.onLoadData();
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_dtList == null) {
      return SizedBox.shrink();
    }

    List<Widget> children = [];

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
  Future<void> SaveData() async {
    close();
  }

  @override
  Widget buildHeader() {
    return SizedBox.shrink();
  }

  @override
  Widget buildFooter() {
    return SizedBox.shrink();
  }

  @override
  // ignore: override_on_non_overriding_member
  Widget buildItemList(BuildContext context, CyberDataRow row, int index) {
    return SizedBox.shrink();
  }
}
