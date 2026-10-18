## 1.0.0

- Initial release of `enum_parser`.
- Added `EnumParserMode` enum featuring `strict`, `simple`, and `loose` matching strategies.
- Added `EnumParser` utility class providing `parse`, `parseStrict`, `parseSimple`, and `parseLoose`.
- Added list parsing support via `parseList`, `parseListStrict`, `parseListSimple`, and `parseListLoose`.
- Added `EnumIndex` for high-throughput pre-computed lookups with immutable snapshot isolation.
- Added deterministic first-match resolution for colliding enum definitions across all matching modes.
- Added enum-to-enum mapping and case-convention conversions.
- Added `EnumParserX` extension on `Iterable<T extends Enum>` for clean, idiomatic enum parsing syntax.

