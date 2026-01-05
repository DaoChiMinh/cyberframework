import 'package:cyberframework/cyberframework.dart';

class CyberDataPost {
  String? functionName;
  String? strParameter;

  CyberDataPost({this.functionName, this.strParameter});

  Map<String, dynamic> toJson() => {
    'FunctionName': functionName,
    'strParametter': strParameter,
  };

  Future<String> convertToRequestString() async {
    final requestData = {
      'Cyber-Date': DateTime.now().toIso8601String(),
      'Cyber-Token': await UserInfo.strTokenId,
      'Cyber-data': toJson(),
    };

    final jsonStr = jsonEncode(requestData);
    return V_MaHoa(jsonStr);
  }
}
