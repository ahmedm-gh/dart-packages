import 'package:cloneable/cloneable.dart';

part 'whitelist_models.g.dart';

/// Model using @Cloneable(fields: [...]) to whitelist supported fields.
@Cloneable(fields: ['name', 'nickname'])
class WhitelistAnnotationUser {
  final String id;
  final String name;
  final String? nickname;

  const WhitelistAnnotationUser({
    required this.id,
    required this.name,
    this.nickname,
  });
}

/// Model using in-class `cloneableFields` getter to whitelist supported fields.
@Cloneable()
class WhitelistGetterUser {
  final String id;
  final String name;
  final String? nickname;

  const WhitelistGetterUser({
    required this.id,
    required this.name,
    this.nickname,
  });

  List<Object?> get cloneableFields => [name, nickname];
}

/// Model with mixin using in-class `copyWithFields` getter.
@Cloneable()
class WhitelistMixinUser with _$WhitelistMixinUserCloneable {
  final String id;
  final String name;

  const WhitelistMixinUser({
    required this.id,
    required this.name,
  });

  List<Object?> get copyWithFields => [name];
}

/// Model using custom `cloneableFieldsGetter`.
@Cloneable(cloneableFieldsGetter: 'supportedProps')
class WhitelistCustomGetterUser {
  final String id;
  final String name;

  const WhitelistCustomGetterUser({
    required this.id,
    required this.name,
  });

  List<Object?> get supportedProps => [name];
}

/// Model with explicitly empty whitelist [] - generator ignores it completely (like active: false).
@Cloneable(fields: [])
class EmptyWhitelistModel {
  final String title;

  const EmptyWhitelistModel({required this.title});
}
