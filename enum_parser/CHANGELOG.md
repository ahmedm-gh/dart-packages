## 1.0.1

- Major performance optimizations across scalar and list parsing routines (up to 8.47x faster).
- Added `EnumIndex` for high-throughput pre-computed lookups with immutable snapshot isolation.
- Added deterministic first-match resolution for colliding enum definitions across all matching modes.
- Added enum-to-enum mapping and case-convention conversions.
- Added `EnumParserX` extension on `Iterable<T extends Enum>` for clean, idiomatic enum parsing syntax.
- Updated documentation and added repository funding links.

## 1.0.0

- Initial release of `enum_parser`.
