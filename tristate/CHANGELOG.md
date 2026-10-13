## 1.0.3

- Added GitHub sponsorship and community support links to README.

## 1.0.2

- Refined `Val(T value)` and `_Val.value` to `T` for compile-time rejection of `null` on non-nullable types.
- Removed runtime `as T` cast in `_Val.call()`, accelerating explicit `null` resolution by ~5x.
- Added zero-dependency Quick Copy drop-in code snippet to README.

## 1.0.1

- Added 'Getting Started' instructions to README.

## 1.0.0

- Initial version.
