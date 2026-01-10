import 'package:cyberframework/cyberframework.dart';

abstract class CyberBaseEdit extends CyberForm {
  List<CyberTab> get tabs;
  int get initialTabIndex => 0;
  String mode = "M";
  String get saveButtonLabel => setText("Lưu dữ liệu", "Save data");
  bool get showSaveButton => true;

  /// Padding cho nút Save
  EdgeInsets get saveButtonPadding =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);

  /// Override để xử lý khi chuyển tab
  void onTabChanged(int index) {}

  @override
  Widget buildBody(BuildContext context) {
    // if (tabs == null) {
    //   return SizedBox.shrink();
    // }

    List<Widget> children = [];

    // Phần CyberTabView
    List<CyberTab> tabList = tabs;
    if (tabList.isNotEmpty) {
      children.add(
        Expanded(
          child: CyberTabView(
            initialIndex: initialTabIndex,
            tabs: tabList,
            onTabChanged: onTabChanged,
          ),
        ),
      );
    }

    // Phần nút Save
    if (showSaveButton) {
      children.add(
        Padding(
          padding: saveButtonPadding,
          child: CyberButton(label: saveButtonLabel, onClick: SaveData),
        ),
      );
    }

    return Column(children: children);
  }

  @override
  Future<void> SaveData() async {}
  String getXML(List<CyberDataTable> dts, List<String> names) {
    return ToXml(dts, names);
  }

  Future<bool> buildSaveXml({
    String Cp_Name = "",
    String StrParameter = "",
  }) async {
    ReturnData returnData = await context.callApi(
      functionName: Cp_Name,
      parameter: StrParameter,
    );

    if (!returnData.isValid()) return false;

    CyberDataset? ds = returnData.toCyberDataset();

    if (ds == null) return false;

    if (!await ds.checkStatus(context)) return false;

    return true;
  }
}
