// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constructor_models.dart';

// **************************************************************************
// CloneableGenerator
// **************************************************************************

/// Strongly-typed copyWith function signature for [Coordinate].
typedef $CoordinateCopyWith = Coordinate Function({
  double x,
  double y,
  double? z,
});

/// Generated cloneable mixin for [Coordinate].
mixin _$CoordinateCloneable {
  $CoordinateCopyWith get copyWith => _copyWith;

  Coordinate _copyWith({
    Object? x = cloneableUndefined,
    Object? y = cloneableUndefined,
    Object? z = cloneableUndefined,
  }) {
    final self = this as Coordinate;
    return Coordinate(
      identical(x, cloneableUndefined) ? self.x : x as double,
      identical(y, cloneableUndefined) ? self.y : y as double,
      identical(z, cloneableUndefined) ? self.z : z as double?,
    );
  }
}

/// Strongly-typed copyWith function signature for [ServiceConfig].
typedef $ServiceConfigCopyWith = ServiceConfig Function({
  String host,
  int port,
  bool? enableSsl,
});

/// Generated cloneable mixin for [ServiceConfig].
mixin _$ServiceConfigCloneable {
  $ServiceConfigCopyWith get copyWith => _copyWith;

  ServiceConfig _copyWith({
    Object? host = cloneableUndefined,
    Object? port = cloneableUndefined,
    Object? enableSsl = cloneableUndefined,
  }) {
    final self = this as ServiceConfig;
    return ServiceConfig.create(
      host: identical(host, cloneableUndefined) ? self.host : host as String,
      port: identical(port, cloneableUndefined) ? self.port : port as int,
      enableSsl: identical(enableSsl, cloneableUndefined)
          ? self.enableSsl
          : enableSsl as bool?,
    );
  }
}

/// Strongly-typed copyWith function signature for [AuditedEntity].
typedef $AuditedEntityCopyWith = AuditedEntity Function({
  String id,
  String title,
});

/// Generated cloneable mixin for [AuditedEntity].
mixin _$AuditedEntityCloneable {
  $AuditedEntityCopyWith get copyWith => _copyWith;

  AuditedEntity _copyWith({
    Object? id = cloneableUndefined,
    Object? title = cloneableUndefined,
  }) {
    final self = this as AuditedEntity;
    return AuditedEntity(
      id: identical(id, cloneableUndefined) ? self.id : id as String,
      title:
          identical(title, cloneableUndefined) ? self.title : title as String,
      createdAt: self.createdAt,
    );
  }
}
