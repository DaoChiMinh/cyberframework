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

  Future<(CyberDataset? ms, bool status)> callApiAndCheck({
    required String functionName,
    String? parameter,
    bool showLoading = true,
    bool showError = true,
    bool isCheckNullData = true,
  }) async {
    final dataPost = CyberDataPost(
      functionName: functionName,
      strParameter: parameter,
    );

    ReturnData returnData = await CyberApiService().callApi(
      context: this,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );

    if (!returnData.isValid()) {
      if (returnData.message != null) {
        await returnData.message!.V_MsgBox(this, type: CyberMsgBoxType.error);
      }
      return (null, false);
    }
    CyberDataset? ds = returnData.toCyberDataset();
    if (ds == null && isCheckNullData) return (null, false);
    if (ds != null) {
      if (!await ds.checkStatus(this)) return (null, false);
    }
    return (ds, true);
  }

  Future<ReturnData> v_dns({
    String dns = '',
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().v_dns(
      context: this,
      dns: dns,
      showLoading: showLoading,
      showError: showError,
    );
  }
}
