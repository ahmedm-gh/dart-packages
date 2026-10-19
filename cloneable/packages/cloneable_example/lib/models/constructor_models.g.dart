// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constructor_models.dart';

/// Strongly-typed copyWith function signature for [Coordinate].
typedef $CoordinateCopyWithFn = Coordinate Function({
  double x,
  double y,
  double? z,
});

/// Generated cloneable mixin for [Coordinate].
mixin _$CoordinateCloneable {
  $CoordinateCopyWithFn get copyWith => _copyWith;

  Coordinate _copyWith({
    Object? x = $undefined,
    Object? y = $undefined,
    Object? z = $undefined,
  }) {
    final self = this as Coordinate;
    return Coordinate(
      identical(x, $undefined) ? self.x : x as double,
      identical(y, $undefined) ? self.y : y as double,
      identical(z, $undefined) ? self.z : z as double?,
    );
  }
}

/// Strongly-typed copyWith function signature for [ServiceConfig].
typedef $ServiceConfigCopyWithFn = ServiceConfig Function({
  String host,
  int port,
  bool? enableSsl,
});

/// Generated cloneable mixin for [ServiceConfig].
mixin _$ServiceConfigCloneable {
  $ServiceConfigCopyWithFn get copyWith => _copyWith;

  ServiceConfig _copyWith({
    Object? host = $undefined,
    Object? port = $undefined,
    Object? enableSsl = $undefined,
  }) {
    final self = this as ServiceConfig;
    return ServiceConfig.create(
      host: identical(host, $undefined) ? self.host : host as String,
      port: identical(port, $undefined) ? self.port : port as int,
      enableSsl: identical(enableSsl, $undefined)
          ? self.enableSsl
          : enableSsl as bool?,
    );
  }
}

/// Strongly-typed copyWith function signature for [AuditedEntity].
typedef $AuditedEntityCopyWithFn = AuditedEntity Function({
  String id,
  String title,
});

/// Generated cloneable mixin for [AuditedEntity].
mixin _$AuditedEntityCloneable {
  $AuditedEntityCopyWithFn get copyWith => _copyWith;

  AuditedEntity _copyWith({
    Object? id = $undefined,
    Object? title = $undefined,
  }) {
    final self = this as AuditedEntity;
    return AuditedEntity(
      id: identical(id, $undefined) ? self.id : id as String,
      title: identical(title, $undefined) ? self.title : title as String,
      createdAt: self.createdAt,
    );
  }
}
