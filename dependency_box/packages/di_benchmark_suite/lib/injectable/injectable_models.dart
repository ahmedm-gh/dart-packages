import 'package:injectable/injectable.dart';

// ============================================================================
// Injectable Graph Models
// ============================================================================

@singleton
class InjAppConfig {
  final String env = 'production';
  final String apiUrl = 'https://api.example.com';
  InjAppConfig();
}

@lazySingleton
class InjLocalStorage {
  final String path = '/var/data.db';
}

@injectable
class InjHttpClient {
  final InjAppConfig config;
  InjHttpClient(this.config);
}

@injectable
class InjUserRepository {
  final InjAppConfig config;
  final InjLocalStorage storage;
  final InjHttpClient client;
  InjUserRepository(this.config, this.storage, this.client);
}

@injectable
class InjUserService {
  final InjUserRepository repository;
  InjUserService(this.repository);
}

// Deep Chain
@singleton
class InjDeepLevel1 {
  final int id = 1;
}

@injectable
class InjDeepLevel2 {
  final InjDeepLevel1 level1;
  InjDeepLevel2(this.level1);
}

@injectable
class InjDeepLevel3 {
  final InjDeepLevel2 level2;
  InjDeepLevel3(this.level2);
}

@injectable
class InjDeepLevel4 {
  final InjDeepLevel3 level3;
  InjDeepLevel4(this.level3);
}

@injectable
class InjDeepLevel5 {
  final InjDeepLevel4 level4;
  InjDeepLevel5(this.level4);
}

// Keyed / Named Singletons
@Named('primary')
@singleton
class InjKeyedPrimary {
  final String tag = 'primary';
}

@Named('secondary')
@singleton
class InjKeyedSecondary {
  final String tag = 'secondary';
}
