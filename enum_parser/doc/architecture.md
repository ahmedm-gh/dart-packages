# Architecture & Design of `enum_parser`

`enum_parser` is designed as a zero-dependency, high-throughput utility for safely parsing and resolving Dart enums from dynamic, loose, and heterogeneous input sources.

## Design Goals

1. **Zero Runtime Dependencies**: Pure Dart implementation that runs identically on all 6 platforms (Android, iOS, Web/WASM, macOS, Linux, Windows).
2. **Matching Strategy Flexibility**: Support multiple parsing strategies:
   - `EnumParserMode.strict`: Case-sensitive exact matching against `Enum.name` without any transformations.
   - `EnumParserMode.simple`: Fast case-insensitive comparison against lowercased names.
   - `EnumParserMode.loose`: Delimiter-agnostic (strips spaces, underscores, hyphens) and type-prefix-stripping (`Enum.name`) matching.
3. **High-Throughput Optimization**:
   - Direct enum instance return short-circuits.
   - Zero regex evaluation; delimiter checks use branch-optimized ASCII and Unicode code unit ranges.
   - ASCII lowercase conversions avoid intermediate string allocations where possible.
   - `EnumIndex` pre-computes lookup tables once to allow $O(1)$ resolutions during high-frequency parsing.
   - `parseList` employs tiered optimization:
     - Single-item or separator-free input: Direct scalar parsing when applicable, avoiding tokenization and collection allocations.
     - Up to 16 input items: Linear parsing avoiding map and index instantiation overhead.
     - More than 16 input items: `EnumIndex` delegation for amortized $\mathcal{O}(V + N)$ execution.
     *(Note: The 16-item cutoff is a benchmark-informed heuristic designed to balance ephemeral map allocation overhead against collection scaling for typical enum cardinalities, rather than a universal performance optimum).*

