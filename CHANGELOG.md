# 0.2.0

Breaking changes! 

- Adds new macros `defparams/1` and `defparams/2`
- Adds `changeset/1` and `changeset/2` to build changesets from schemas defined with `defparams/2`.
- Adds `validate/1` and `validate/2` to validate changesets built from schemas defined with `defparams/2`.
- Adds `action: :validate` in returned changesets
- Switches the order of arguments in `validate_params/2`
- Switches the order of arguments in `build_changeset/2`

Migration instructions:

1. Replace `import Goal.Syntax` with `import Goal`
2. Switch the arguments for `validate_params/2` from `validate_params(data, schema)` to `validate_params(schema, data)`
3. Switch the arguments for `build_changeset/2` from `build_changeset(data, schema)` to `validate_params(schema, data)`

See the docs for more information on the new `defparams` macro.

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
