import 'package:cyberframework/cyberframework.dart';
import 'package:get_it/get_it.dart';
import 'spscreen.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  getIt.init();
  buildFactoryMap();
}
