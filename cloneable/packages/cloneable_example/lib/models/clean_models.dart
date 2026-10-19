import 'package:cloneable/cloneable.dart';

part 'clean_models.g.dart';

/// Clean model with NO mixin declaration - uses extension strategy via auto-detection!
@Cloneable()
class CleanUser {
  final String id;
  final String name;
  final int age;
  final String? bio;

  const CleanUser({
    required this.id,
    required this.name,
    required this.age,
    this.bio,
  });
}

/// Model explicitly requesting extension strategy.
@Cloneable(strategy: CloneableStrategy.extension, deepCopyCollections: true)
class CleanProduct {
  final String sku;
  final double price;
  final List<String> tags;

  const CleanProduct({
    required this.sku,
    required this.price,
    required this.tags,
  });
}

/// Model with identical fields to [User] to benchmark Extension vs Mixin directly.
@Cloneable(strategy: CloneableStrategy.extension)
class ExtensionUser {
  final String name;
  final int age;
  final String? nickname;

  const ExtensionUser({
    required this.name,
    required this.age,
    this.nickname,
  });
}

/// Example of defining a project-wide type alias for [Cloneable].
typedef UseCopyWith = Cloneable;

/// Model annotated with the custom [UseCopyWith] type alias.
@UseCopyWith()
class AliasedUserModel {
  final String name;
  final int age;

  const AliasedUserModel({
    required this.name,
    required this.age,
  });
}

/// Model with custom prefix ('Custom') using extension in a part-file approach.
@Cloneable(
  naming: CloneableNaming(
    extension: CloneableAffix(prefix: 'Custom'),
  ),
)
class CustomPrefixUser {
  final String name;
  final String email;

  const CustomPrefixUser({
    required this.name,
    required this.email,
  });
}

/// Model with custom prefix ('_') using mixin in a part-file approach.
@Cloneable(
  strategy: CloneableStrategy.mixin,
  naming: CloneableNaming(
    mixin: CloneableAffix(prefix: '_'),
  ),
)
class CustomMixinUser with _CustomMixinUserCloneable {
  final String name;
  final String email;

  const CustomMixinUser({
    required this.name,
    required this.email,
  });
}
