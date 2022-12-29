# 0.1.3

No breaking changes.

- Exposes `build_changeset/2` in the main namespace (`Goal`)
- Updates documentation for use with LiveViews

# 0.1.2

No breaking changes.

- Adds `:uuid` type
- Improves password regex to allow non-alphanumeric characters

# 0.1.1

No breaking changes.

- Allow number validations for all number fields (incl. `:decimal`, `:float`)
- Adds performance optimizations to the validation logic
- Adds tests to confirm `traverse_errors/2` doesn't break embedded Ecto schemas
- Refactors the validation logic
- Updates documentation

# 0.1.0

No breaking changes.

- Adds `defschema` macro for defining validation schemas with less boilerplate

# 0.0.1

- Initial release
