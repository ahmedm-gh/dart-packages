import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injectable_setup.config.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies(GetIt getIt) {
  getIt.init();
}
