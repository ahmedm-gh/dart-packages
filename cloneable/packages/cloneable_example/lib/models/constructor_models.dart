import 'package:cloneable/cloneable.dart';

part 'constructor_models.g.dart';

@Cloneable()
class Coordinate with _$CoordinateCloneable {
  final double x;
  final double y;
  final double? z;

  const Coordinate(
    this.x,
    this.y, [
    this.z,
  ]);
}

@Cloneable(constructor: 'create')
class ServiceConfig with _$ServiceConfigCloneable {
  final String host;
  final int port;
  final bool? enableSsl;

  const ServiceConfig.create({
    required this.host,
    required this.port,
    this.enableSsl,
  });
}

@Cloneable()
class AuditedEntity with _$AuditedEntityCloneable {
  final String id;
  final String title;
  @CloneableField(ignore: true)
  final DateTime createdAt;

  const AuditedEntity({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}
