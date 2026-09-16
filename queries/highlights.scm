; Keywords
[
  "let"
  "fn"
  "dimension"
  "unit"
  "struct"
  "use"
  "where"
  "and"
  "if"
  "then"
  "else"
] @keyword

; Operators
[
  "|>"
  "->"
  "→"
  "➞"
  "to"
  "||"
  "&&"
  "<"
  ">"
  "<="
  ">="
  "≤"
  "≥"
  "=="
  "!="
  "⩵"
  "≠"
  "+"
  "-"
  "−"
  "*"
  "/"
  "×"
  "·"
  "⋅"
  "÷"
  "per"
  "^"
  "**"
  "!"
] @operator

; Brackets
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

; Delimiters
[
  ","
  ";"
  "."
  "::"
  ":"
  "="
  "@"
] @punctuation.delimiter

; ---------------------------------------------------------------------------
; Literals
; ---------------------------------------------------------------------------

(comment) @comment

[
  (decimal_number)
  (hex_number)
  (octal_number)
  (binary_number)
] @number

[
  (nan)
  (inf)
  (boolean)
] @constant.builtin

(typed_hole) @variable.builtin

(string) @string
(string_content) @string
(format_specifier) @string.special

(interpolation
  "{" @punctuation.special
  "}" @punctuation.special)

; Generic fallback for bare identifiers. Placed early: later, more specific
; captures below override it.
(identifier) @variable

; ---------------------------------------------------------------------------
; Types
; ---------------------------------------------------------------------------

(boolean_type) @type.builtin
(string_type) @type.builtin
(datetime_type) @type.builtin
"Fn" @type.builtin
"List" @type.builtin

(dimension_primary
  (identifier) @type)

(type_parameter
  (identifier) @type)

; `<`/`>` in generic positions are brackets, not comparisons.
(type_parameters
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

(type_arguments
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

(list_type
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

; ---------------------------------------------------------------------------
; Definitions and references
; ---------------------------------------------------------------------------

(variable_declaration
  (identifier) @variable)

(function_declaration
  (identifier) @function)

(parameter
  (identifier) @variable.parameter)

(struct_declaration
  (identifier) @type)

(dimension_declaration
  (identifier) @type)

(unit_declaration
  (identifier) @constant)

(module_import
  (identifier) @module)

(decorator
  (identifier) @attribute)

(call_expression
  (primary
    (identifier) @function.call))

; Fields / properties
(field_access
  (identifier) @property)

(struct_field
  (identifier) @property)

(struct_instantiation_field
  (identifier) @property)

; Built-in procedures
(procedure_call
  [
    "print"
    "assert"
    "assert_eq"
    "type"
  ] @function.builtin)
