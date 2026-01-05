import 'package:cyberframework/cyberframework.dart';
import 'spscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return V_Root("MyHomePage");
  }
}

@Singleton(as: CyberForm)
@named
class MyHomePage extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Center(child: Text("Hello World", style: TextStyle(fontSize: 24)));
  }
}
