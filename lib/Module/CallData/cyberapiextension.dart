import 'package:cyberframework/cyberframework.dart';

extension CyberApiExtension on BuildContext {
  Future<ReturnData> callApi({
    required String functionName,
    String? parameter,
    bool showLoading = true,
    bool showError = true,
  }) {
    final dataPost = CyberDataPost(
      functionName: functionName,
      strParameter: parameter,
    );

    return CyberApiService().callApi(
      context: this,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );
  }
}
