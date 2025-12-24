import 'package:cyberframework/cyberframework.dart';

class Frmwebview extends CyberForm {
  String? Url;
  @override
  bool? get hideAppBar => false;

  @override
  String? get title => Url ?? "WebView";

  @override
  Color? get backgroundColor => Colors.white;

  @override
  Widget buildBody(BuildContext context) {
    return CyberWebView(url: Url);
  }
}
