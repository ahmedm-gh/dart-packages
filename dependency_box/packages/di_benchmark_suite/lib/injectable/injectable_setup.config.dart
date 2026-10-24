// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'injectable_models.dart' as _i832;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i832.InjAppConfig>(() => _i832.InjAppConfig());
    gh.singleton<_i832.InjDeepLevel1>(() => _i832.InjDeepLevel1());
    gh.lazySingleton<_i832.InjLocalStorage>(() => _i832.InjLocalStorage());
    gh.singleton<_i832.InjKeyedSecondary>(
      () => _i832.InjKeyedSecondary(),
      instanceName: 'secondary',
    );
    gh.singleton<_i832.InjKeyedPrimary>(
      () => _i832.InjKeyedPrimary(),
      instanceName: 'primary',
    );
    gh.factory<_i832.InjHttpClient>(
        () => _i832.InjHttpClient(gh<_i832.InjAppConfig>()));
    gh.factory<_i832.InjDeepLevel2>(
        () => _i832.InjDeepLevel2(gh<_i832.InjDeepLevel1>()));
    gh.factory<_i832.InjUserRepository>(() => _i832.InjUserRepository(
          gh<_i832.InjAppConfig>(),
          gh<_i832.InjLocalStorage>(),
          gh<_i832.InjHttpClient>(),
        ));
    gh.factory<_i832.InjDeepLevel3>(
        () => _i832.InjDeepLevel3(gh<_i832.InjDeepLevel2>()));
    gh.factory<_i832.InjUserService>(
        () => _i832.InjUserService(gh<_i832.InjUserRepository>()));
    gh.factory<_i832.InjDeepLevel4>(
        () => _i832.InjDeepLevel4(gh<_i832.InjDeepLevel3>()));
    gh.factory<_i832.InjDeepLevel5>(
        () => _i832.InjDeepLevel5(gh<_i832.InjDeepLevel4>()));
    return this;
  }
}
