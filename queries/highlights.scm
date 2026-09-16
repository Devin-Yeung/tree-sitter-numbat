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
; Built-in units
;
; The prelude (`numbat/modules/`) defines several hundred units and aliases.
; We highlight a narrowed, programming-oriented subset: data sizes, time and
; counts, plus the core SI units. Domain units (physics, astronomy, imperial,
; cooking, ...) are intentionally left out, as they collide with ordinary
; identifier names far more often than they appear in code.
;
; Deliberately *not* highlighted:
;   - short aliases (`m`, `s`, `g`, `A`, ...): a local variable may shadow a
;     unit, and a syntax-only highlighter cannot tell the two apart;
;   - units that read like ordinary variables (`query`, `request`, `person`,
;     `piece`, `frame`, `dot`, `beat`, `turn`, ...).
;
; Registered unit names below come from `numbat list units`. The prefixed forms
; are synthesized by `numbat/src/prefix_parser.rs` and do not appear in that
; list.
; ---------------------------------------------------------------------------

; Registered unit names / long aliases.
((identifier) @constant.builtin
  (#any-of? @constant.builtin
    "Byte" "Bytes" "ampere" "amperes" "becquerel" "becquerels" "billion" "bit"
    "bits" "byte" "bytes" "candela" "candelas" "centuries" "century" "coulomb"
    "coulombs" "day" "days" "decade" "dozen" "farad" "farads" "gram"
    "grams" "gray" "grays" "henries" "henry" "henrys" "hertz" "hour"
    "hours" "hundred" "joule" "joules" "katal" "katals" "kelvin" "liter"
    "liters" "litre" "litres" "lumen" "lumens" "lux" "meter" "meters"
    "metre" "metres" "millennia" "millennium" "million" "min" "minute" "minutes"
    "mole" "moles" "month" "months" "newton" "newtons" "nibble" "nibbles"
    "octet" "octets" "ohm" "ohms" "partsperbillion" "partspermillion" "pascal" "pascals"
    "percent" "permille" "radian" "radians" "sec" "second" "seconds" "siemens"
    "sievert" "sieverts" "steradian" "steradians" "tesla" "teslas" "thousand" "tonne"
    "tonnes" "trillion" "unix_ms" "unix_s" "volt" "volts" "watt" "watts"
    "weber" "webers" "week" "weeks" "year" "years"
  ))

; Long prefix + long unit, e.g. `kilometer`, `megabyte`, `microsecond`.
((identifier) @constant.builtin
  (#match? @constant.builtin
    "^(quecto|ronto|yocto|zepto|atto|femto|pico|nano|micro|milli|centi|deci|deca|hecto|kilo|mega|giga|tera|peta|exa|zetta|yotta|ronna|quetta|kibi|mebi|gibi|tebi|pebi|exbi|zebi|yobi|robi|quebi)(metre|meter|second|gram|ampere|kelvin|mole|candela|radian|steradian|hertz|newton|pascal|joule|watt|coulomb|volt|farad|ohm|siemens|weber|tesla|henry|lumen|lux|becquerel|gray|sievert|katal|litre|liter|byte|bit|tonne)s?$"))

; Capitalized byte forms, e.g. `MByte`, `kBytes`, `megaByte`, `MiByte`.
((identifier) @constant.builtin
  (#match? @constant.builtin
    "^(k|M|G|T|P|E|Z|Y|R|Q|Ki|Mi|Gi|Ti|Pi|Ei|Zi|Yi|Ri|Qi|kilo|mega|giga|tera|peta|exa|zetta|yotta|ronna|quetta|kibi|mebi|gibi|tebi|pebi|exbi|zebi|yobi|robi|quebi)(Byte|Bytes)$"))

; Common short prefixed forms, e.g. `kg`, `MB`, `MiB`, `GHz`.
((identifier) @constant.builtin
  (#any-of? @constant.builtin
    "EB" "Ebit" "EiB" "GB" "GHz" "GJ" "GPa" "GW"
    "GWh" "Gbit" "GeV" "GiB" "KB" "KiB" "MB" "MHz"
    "MJ" "MPa" "MW" "MWh" "Mbit" "MeV" "MiB" "MΩ"
    "PB" "Pbit" "PiB" "QB" "QiB" "RB" "RiB" "TB"
    "THz" "TJ" "TW" "Tbit" "TeV" "TiB" "YB" "YiB"
    "ZB" "ZiB" "cL" "cm" "dL" "fm"
    "hPa" "kA" "kB" "kHz" "kJ"
    "kL" "kN" "kPa" "kV" "kW" "kWh" "kbit" "keV"
    "kg" "km" "kmol" "kΩ" "mA" "mL" "mN" "mV"
    "mg" "mm" "mmol" "ms" "mΩ" "nm" "ns" "pm"
    "ps" "°C" "°F" "µA" "µL" "µV"
    "µg" "µm" "µmol" "µs" "Ω" "μA" "μL" "μV"
    "μg" "μm" "μmol" "μs"

    ; Data rates (bits per second), e.g. `Mbps`, `Gbps`.
    "bps" "kbps" "Mbps" "Gbps" "Tbps" "Pbps" "Ebps" "Zbps" "Ybps"
  ))


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

; Built-in functions from the prelude. Restricted to call position, so a user
; definition with the same name is only miscoloured where it is actually called.
((call_expression
   (primary
     (identifier) @function.builtin))
  (#any-of? @function.builtin
    "abs" "acos" "acosh" "acot" "acoth" "acsc"
    "acsch" "add" "arcsecant" "args" "asech" "asin"
    "asinh" "atan" "atan2" "atanh" "bar_chart" "base"
    "base_unit_of" "bin" "binom" "calendar_add" "calendar_sub" "catalan"
    "cbrt" "ceil" "ceil_in" "celsius" "chr" "circle_area"
    "circle_circumference" "color" "color_hex" "color_rgb" "color_rgb_float" "concat"
    "cons" "cons_end" "contains" "cos" "cosecant" "cosh"
    "cot" "coth" "cross" "csc" "csch" "cubic_equation"
    "date" "datetime" "dec" "decrease_by" "degree_celsius" "degree_fahrenheit"
    "diff" "DM" "DMS" "dot_product" "drop" "dsolve_runge_kutta"
    "element" "element_at" "error" "exchange_rate" "exp" "factorial"
    "fahrenheit" "falling_factorial" "feet_and_inches" "fibonacci" "filter" "fixed_point"
    "floor" "floor_in" "foldl" "format_datetime" "fract" "from_celsius"
    "from_fahrenheit" "from_julian_date" "from_unixtime" "from_unixtime_ms" "from_unixtime_s" "from_unixtime_µs"
    "from_unixtime_us" "gamma" "gcd" "get_local_timezone" "has_unit" "head"
    "hex" "human" "hypot2" "hypot3" "id" "increase_by"
    "inspect" "intersperse" "is_dimensionless" "is_empty" "is_finite" "is_infinite"
    "is_integer" "is_nan" "is_nonzero" "is_zero" "join" "julian_date"
    "lcm" "len" "length" "line_plot" "linspace" "ln"
    "log" "log10" "log2" "lowercase" "lucas" "map"
    "map2" "maximum" "mean" "median" "minimum" "mod"
    "moon_phase" "moon_phase_name" "multiply" "norm" "now" "oct"
    "ord" "parse" "percentage_change" "pounds_and_ounces" "quadratic_equation" "quantity_cast"
    "rand_bernoulli" "rand_binom" "rand_expon" "rand_geom" "rand_int" "rand_lognorm"
    "rand_norm" "rand_pareto" "rand_poisson" "rand_uniform" "random" "range"
    "reverse" "rgb" "root_bisect" "root_newton" "round" "round_in"
    "secant" "sech" "show" "sin" "sinh" "sort"
    "sort_by_key" "speed_of_sound" "sphere_area" "sphere_volume" "split" "sqr"
    "sqrt" "stdev" "str_append" "str_contains" "str_find" "str_length"
    "str_prepend" "str_repeat" "str_replace" "str_slice" "sum" "sunrise_sunset"
    "tail" "take" "tan" "tanh" "time" "today"
    "trunc" "trunc_in" "tz" "unique" "unit_list" "unit_name"
    "unit_of" "unixtime" "unixtime_ms" "unixtime_s" "unixtime_µs" "unixtime_us"
    "uppercase" "value_label" "value_of" "variance" "vec" "weekday"
    "xlabel" "xlabels" "ylabel"
  ))

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
