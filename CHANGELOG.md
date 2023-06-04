# 0.3.0

- Adds support for validation on array items (https://github.com/martinthenth/goal/pull/50 - by [@LukasKnuth](https://github.com/LukasKnuth))
- Adds support for Regex validation in `defparams` (https://github.com/martinthenth/goal/pull/53 - by [@LukasKnuth](https://github.com/LukasKnuth))
- Adds the `:any` field type in `defparams`, enabling presence checks without validation
- Fixes a bug with optional arrays of maps
- Removes `defschema` in favor of `defparams`

Migration instructions:

1.  Replace `defschema` with `defparams` definitions

# 0.2.5

- Fixes a bug with recasing inbound keys when an empty map is given as parameter

# 0.2.4

- Fixes a bug with `recase_keys: [from: :camel_case]` where empty values were ignored

# 0.2.3

- Adds `recase_keys/2` for recasing outbound keys
- Adds optional `:to_case` option to `:recase_keys` global configuration
- Adds fallback to non-recased parameters when recasing inbound parameters

# 0.2.2

- Fixes a bug in `recase_keys/4` when it receives a value that isn't a map or list of maps

# 0.2.1

- Adds `recase_keys/3` to recase parameter keys from `camelCase`, `snake_case`, `PascalCase` or `kebab-case`
- Adds optional `:recase_keys` configuration to `validate/3` and `validate_params/3`
- Adds optional `:recase_keys` global configuration

# 0.2.0

- Adds new macros `defparams/1` and `defparams/2`
- Adds `changeset/1` and `changeset/2` to build changesets from schemas defined with `defparams/2`.
- Adds `validate/1` and `validate/2` to validate changesets built from schemas defined with `defparams/2`.
- Adds `action: :validate` in returned changesets
- Switches the order of arguments in `validate_params/2`
- Switches the order of arguments in `build_changeset/2`

Migration instructions:

1. Replace `import Goal.Syntax` with `import Goal`
2. Switch the arguments for `validate_params/2` from `validate_params(data, schema)` to `validate_params(schema, data)`
3. Switch the arguments for `build_changeset/2` from `build_changeset(data, schema)` to `build_changeset(schema, data)`

See the docs for more information on the new `defparams` macro.

# 0.1.3

- Exposes `build_changeset/2` in the main namespace (`Goal`)
- Updates documentation for use with LiveViews

# 0.1.2

- Adds `:uuid` type
- Improves password regex to allow non-alphanumeric characters

# 0.1.1

- Allow number validations for all number fields (incl. `:decimal`, `:float`)
- Adds performance optimizations to the validation logic
- Adds tests to confirm `traverse_errors/2` doesn't break embedded Ecto schemas
- Refactors the validation logic
- Updates documentation

# 0.1.0

- Adds `defschema` macro for defining validation schemas with less boilerplate

# 0.0.1

- Initial release
