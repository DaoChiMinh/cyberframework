import 'package:cyberframework/cyberframework.dart';

abstract class CyberBaseEdit extends CyberForm {
  List<CyberTab> get tabs;
  int get initialTabIndex => 0;
  String mode = "M";
  String get saveButtonLabel => setText("Lưu dữ liệu", "Save data");
  bool get showSaveButton => true;
  final ReturnFormData _formData = ReturnFormData(isOk: false);

  /// Padding cho nút Save
  EdgeInsets get saveButtonPadding =>
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);

  /// Override để xử lý khi chuyển tab
  @override
  void onTabChanged(int index) {
    print("aaaaaaaaaaaaaaaaa");
  }

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
    children.add(buildFooter());
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
  // ignore: override_on_non_overriding_member
  Widget buildFooter() {
    return SizedBox.shrink();
  }

  @override
  // ignore: override_on_non_overriding_member
  Future<void> SaveData() async {
    close(result: _formData);
  }

  String getXML(List<CyberDataTable> dts, List<String> names) {
    return ToXml(dts, names);
  }

  Future<bool> buildSaveXml({
    String Cp_Name = "",
    String StrParameter = "",
  }) async {
    _formData.isOk = false;
    ReturnData returnData = await context.callApi(
      functionName: Cp_Name,
      parameter: StrParameter,
    );

    if (!returnData.isValid()) return false;

    CyberDataset? ds = returnData.toCyberDataset();

    if (ds == null) {
      await "Data NULL".V_MsgBox(context, type: CyberMsgBoxType.error);
      return false;
    }

    if (!await ds.checkStatus(context)) return false;
    if (ds.tableCount < 2) {
      await "Không tồn tại bảng 2".V_MsgBox(
        context,
        type: CyberMsgBoxType.error,
      );
      return false;
    }
    if (ds[1]!.rowCount > 0) {
      _formData.isOk = true;
      _formData.objectData = ds[1]![0];
    }
    return true;
  }
}
