import 'package:cyberframework/cyberframework.dart';

@Singleton(as: CyberForm)
@named
class Frmplashscreen extends CyberForm {
  @override
  Future<void> onAfterLoad() async {
    bool isLogin = await UserInfo.V_Login(context, "", "", "");
    String strscreen = "FrmLogin";
    if (isLogin) strscreen = "FrmMain";

    // ignore: use_build_context_synchronously
    V_MainScreen(context, strscreen);
    return super.onAfterLoad();
  }

  @override
  Widget buildBody(BuildContext context) {
    return Center(child: Text("Màn hình PlashScreen"));
  }
}
