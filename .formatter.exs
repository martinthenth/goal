# Used by "mix format"
locals_without_parens = [
  defparams: 1,
  defparams: 2,
  optional: 1,
  optional: 2,
  optional: 3,
  required: 1,
  required: 2,
  required: 3
]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
