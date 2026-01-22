import 'package:cyberframework/cyberframework.dart';

class Frmviewfile extends CyberForm {
  dynamic text = "";
  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [Expanded(child: CyberViewFile(text: text))],
    );
  }
}
