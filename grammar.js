/**
 * @file Numbat grammar for tree-sitter
 * @author Devin-Yeung
 * @license MIT
 *
 * This grammar mirrors the recursive-descent parser of the reference Numbat
 * implementation (sharkdp/numbat, `numbat/src/parser.rs` + `tokenizer.rs`).
 *
 * Notable properties of the language:
 *   - Statements are terminated by newlines or `;`. Newlines are *tokens*,
 *     not whitespace. They are, however, explicitly allowed inside bracketed
 *     constructs (argument lists, lists, struct definitions, parameter lists)
 *     and in a few grammar positions (`= <body>`, `where`/`and`, `then`/`else`).
 *   - Juxtaposition (`2 pi`, `1 2`) is implicit multiplication.
 *   - Strings support `{expression}` interpolation, including nested strings.
 *
 * The expression grammar uses hidden pass-through rules (`_term`, `_factor`,
 * …) for the precedence levels that do not correspond to a syntactic
 * construct. This keeps the parse tree flat: only *actual* operator nodes
 * appear, instead of one wrapper node per precedence level.
 */

const PREC = {
  postfix_apply: 1,
  conversion: 3,
  logical_or: 4,
  logical_and: 5,
  logical_neg: 6,
  comparison: 7,
  additive: 8,
  multiplicative: 9,
  per: 10,
  unary: 11,
  implicit_mul: 12,
  power: 13,
  factorial: 14,
  unicode_power: 15,
  call: 20,
};

/**
 * A `,`-separated list wrapped in `open`/`close`, where newlines are allowed
 * after the opening delimiter, after each comma and before the closing
 * delimiter, and where a trailing comma is accepted.
 */
function delimited($, open, item, close) {
  return seq(
    open,
    choice(
      repeat($._nl),
      seq(
        repeat($._nl),
        item,
        repeat(seq(',', repeat($._nl), item)),
        optional(','),
        repeat($._nl),
      ),
    ),
    close,
  );
}

export default grammar({
  name: 'numbat',

  extras: $ => [/[ \t\r]+/, $.comment],

  word: $ => $.identifier,

  conflicts: $ => [
    [$.function_declaration],
    [$.where_clause],
  ],

  rules: {
    // ---------------------------------------------------------------------
    // Top level
    // ---------------------------------------------------------------------

    source_file: $ => seq(
      optional($._statement),
      repeat(seq($._statement_separator, optional($._statement))),
    ),

    _statement_separator: $ => choice($._nl, ';'),

    // A single physical newline (or a run of them). Comments are extras, so a
    // reversed run separated by comments still yields several `_nl` tokens.
    _nl: _ => /\n+/,

    comment: _ => token(seq('#', /[^\n]*/)),

    _statement: $ => choice(
      $.decorated_statement,
      $.variable_declaration,
      $.function_declaration,
      $.dimension_declaration,
      $.unit_declaration,
      $.struct_declaration,
      $.module_import,
      $.procedure_call,
      $.expression,
    ),

    // ---------------------------------------------------------------------
    // Definitions
    // ---------------------------------------------------------------------

    variable_declaration: $ => seq(
      'let',
      $.identifier,
      optional(seq(':', $.type_annotation)),
      '=',
      repeat($._nl),
      $.expression,
    ),

    function_declaration: $ => seq(
      'fn',
      $.identifier,
      optional($.type_parameters),
      $.parameter_list,
      optional(seq('->', $.type_annotation)),
      optional(seq(
        '=',
        repeat($._nl),
        $.expression,
        optional(seq(repeat($._nl), $.where_clause)),
      )),
    ),

    parameter_list: $ => delimited($, '(', $.parameter, ')'),

    parameter: $ => seq(
      $.identifier,
      optional(seq(':', $.type_annotation)),
    ),

    where_clause: $ => seq(
      'where',
      repeat($._nl),
      $.local_variable,
      repeat(seq(repeat($._nl), 'and', repeat($._nl), $.local_variable)),
    ),

    local_variable: $ => seq(
      $.identifier,
      optional(seq(':', $.type_annotation)),
      '=',
      repeat($._nl),
      $.expression,
    ),

    dimension_declaration: $ => seq(
      'dimension',
      $.identifier,
      repeat(seq('=', repeat($._nl), $.dimension_expression)),
    ),

    unit_declaration: $ => seq(
      'unit',
      $.identifier,
      optional(seq(':', repeat($._nl), $.dimension_expression)),
      optional(seq('=', repeat($._nl), $.expression)),
    ),

    struct_declaration: $ => seq(
      'struct',
      $.identifier,
      optional($.type_parameters),
      delimited($, '{', $.struct_field, '}'),
    ),

    struct_field: $ => seq(
      $.identifier,
      repeat($._nl),
      ':',
      repeat($._nl),
      $.type_annotation,
    ),

    module_import: $ => seq(
      'use',
      $.identifier,
      repeat(seq('::', $.identifier)),
    ),

    procedure_call: $ => seq(
      choice('print', 'assert', 'assert_eq', 'type'),
      $.argument_list,
    ),

    decorated_statement: $ => seq(
      repeat1(seq($.decorator, repeat($._nl))),
      choice(
        $.variable_declaration,
        $.function_declaration,
        $.unit_declaration,
      ),
    ),

    decorator: $ => seq(
      '@',
      $.identifier,
      optional($.decorator_arguments),
    ),

    decorator_arguments: $ => delimited($, '(', $._decorator_argument, ')'),

    _decorator_argument: $ => choice(
      $.string,
      $.identifier,
      seq(
        $.identifier,
        ':',
        choice($.identifier, 'long', 'short', 'both', 'none'),
      ),
    ),

    // ---------------------------------------------------------------------
    // Types
    // ---------------------------------------------------------------------

    type_parameters: $ => delimited($, '<', $.type_parameter, '>'),

    type_parameter: $ => seq(
      $.identifier,
      optional(seq(':', $.identifier)),
    ),

    type_annotation: $ => choice(
      $.boolean_type,
      $.string_type,
      $.datetime_type,
      $.function_type,
      $.list_type,
      $.dimension_expression,
    ),

    boolean_type: _ => 'Bool',
    string_type: _ => 'String',
    datetime_type: _ => 'DateTime',

    function_type: $ => seq(
      'Fn',
      '[',
      repeat($._nl),
      delimited($, '(', $.type_annotation, ')'),
      repeat($._nl),
      '->',
      repeat($._nl),
      $.type_annotation,
      repeat($._nl),
      ']',
    ),

    list_type: $ => seq(
      'List',
      '<',
      repeat($._nl),
      $.type_annotation,
      repeat($._nl),
      '>',
    ),

    // A dimension expression, i.e. the "quantity type" of numbat.
    dimension_expression: $ => $.dimension_factor,

    dimension_factor: $ => choice(
      $.dimension_power,
      prec.left(1, seq(
        $.dimension_factor,
        choice('*', '/', '×', '·', '⋅', '÷'),
        $.dimension_power,
      )),
    ),

    dimension_power: $ => choice(
      $.dimension_primary,
      prec(1, seq($.dimension_primary, choice('^', '**'), $.dimension_exponent)),
      prec(1, seq($.dimension_primary, $.unicode_exponent)),
    ),

    dimension_exponent: $ => choice(
      $.number,
      prec(2, seq($._minus, $.dimension_exponent)),
      seq(
        '(',
        repeat($._nl),
        $.dimension_exponent,
        optional(seq(
          repeat($._nl),
          '/',
          repeat($._nl),
          $.dimension_exponent,
        )),
        repeat($._nl),
        ')',
      ),
    ),

    dimension_primary: $ => choice(
      $.identifier,
      prec(1, seq($.identifier, $.type_arguments)),
      $.number,
      seq('(', repeat($._nl), $.dimension_expression, repeat($._nl), ')'),
    ),

    type_arguments: $ => delimited($, '<', $.type_annotation, '>'),

    // ---------------------------------------------------------------------
    // Expressions
    //
    // Precedence, lowest to highest (mirrors the reference parser):
    //   postfix apply |>  <  if/then/else  <  conversion -> to  <  ||  <  &&
    //   <  !  <  comparison  <  + -  <  * /  <  per  <  unary + -  <
    //   implicit multiplication  <  ^  <  factorial !  <  unicode exponent
    //   <  call / field access  <  primary
    // ---------------------------------------------------------------------

    expression: $ => $._postfix_apply,

    // |> ------------------------------------------------------------------

    _postfix_apply: $ => choice(
      $._condition,
      $.postfix_apply_expression,
    ),

    postfix_apply_expression: $ => prec.left(PREC.postfix_apply, seq(
      $._postfix_apply,
      '|>',
      repeat($._nl),
      $._call,
    )),

    // if / then / else ----------------------------------------------------

    _condition: $ => choice(
      $._conversion,
      $.if_expression,
    ),

    if_expression: $ => seq(
      'if',
      $._conversion,
      repeat($._nl),
      'then',
      repeat($._nl),
      $._condition,
      repeat($._nl),
      'else',
      repeat($._nl),
      $._condition,
    ),

    // conversion `->` `to` `→` `➞` ----------------------------------------

    _conversion: $ => choice(
      $._logical_or,
      $.conversion_expression,
    ),

    conversion_expression: $ => prec.left(PREC.conversion, seq(
      $._conversion,
      choice('->', '→', '➞', 'to'),
      $._logical_or,
    )),

    // boolean operators ---------------------------------------------------

    _logical_or: $ => choice(
      $._logical_and,
      $.logical_or_expression,
    ),

    logical_or_expression: $ => prec.left(PREC.logical_or, seq(
      $._logical_or,
      '||',
      $._logical_and,
    )),

    _logical_and: $ => choice(
      $._logical_neg,
      $.logical_and_expression,
    ),

    logical_and_expression: $ => prec.left(PREC.logical_and, seq(
      $._logical_and,
      '&&',
      $._logical_neg,
    )),

    _logical_neg: $ => choice(
      $._comparison,
      $.not_expression,
    ),

    not_expression: $ => prec(PREC.logical_neg, seq('!', $._logical_neg)),

    // comparisons ---------------------------------------------------------

    _comparison: $ => choice(
      $._term,
      $.comparison_expression,
    ),

    comparison_expression: $ => prec.left(PREC.comparison, seq(
      $._comparison,
      choice('<', '>', '<=', '>=', '≤', '≥', '==', '!=', '⩵', '≠'),
      $._term,
    )),

    // arithmetic ----------------------------------------------------------

    _term: $ => choice(
      $._factor,
      $.additive_expression,
    ),

    additive_expression: $ => prec.left(PREC.additive, seq(
      $._term,
      choice($._plus, $._minus),
      $._factor,
    )),

    _factor: $ => choice(
      $._per_factor,
      $.multiplicative_expression,
    ),

    multiplicative_expression: $ => prec.left(PREC.multiplicative, seq(
      $._factor,
      choice('*', '/', '×', '·', '⋅', '÷'),
      $._per_factor,
    )),

    _per_factor: $ => choice(
      $._unary,
      $.per_expression,
    ),

    per_expression: $ => prec.left(PREC.per, seq(
      $._per_factor,
      'per',
      $._unary,
    )),

    _unary: $ => choice(
      $._ifactor,
      $.unary_expression,
    ),

    unary_expression: $ => prec(PREC.unary, seq(
      choice($._plus, $._minus),
      $._unary,
    )),

    // implicit multiplication (`2 pi`, `1 2`) -----------------------------

    _ifactor: $ => choice(
      $._power,
      $.implicit_multiplication,
    ),

    implicit_multiplication: $ => prec.left(PREC.implicit_mul, seq(
      $._ifactor,
      $._power,
    )),

    // exponentiation ------------------------------------------------------

    _power: $ => choice(
      $._factorial,
      $.power_expression,
    ),

    power_expression: $ => prec.right(PREC.power, seq(
      $._factorial,
      choice('^', '**'),
      optional($._minus),
      $._power,
    )),

    _factorial: $ => choice(
      $._unicode_power,
      $.factorial_expression,
    ),

    factorial_expression: $ => prec.left(PREC.factorial, seq(
      $._factorial,
      '!',
    )),

    _unicode_power: $ => choice(
      $._call,
      $.unicode_power_expression,
    ),

    unicode_power_expression: $ => prec.left(PREC.unicode_power, seq(
      $._call,
      $.unicode_exponent,
    )),

    // calls and field access ----------------------------------------------

    _call: $ => choice(
      $.primary,
      $.call_expression,
      $.field_access,
    ),

    call_expression: $ => prec.left(PREC.call, seq(
      $._call,
      $.argument_list,
    )),

    field_access: $ => prec.left(PREC.call, seq(
      $._call,
      '.',
      $.identifier,
    )),

    argument_list: $ => delimited($, '(', $.expression, ')'),

    // primaries -----------------------------------------------------------

    primary: $ => choice(
      $.number,
      $.nan,
      $.inf,
      $.boolean,
      $.string,
      $.list,
      $.typed_hole,
      $.struct_instantiation,
      $.identifier,
      $.parenthesized_expression,
    ),

    parenthesized_expression: $ => seq(
      '(',
      repeat($._nl),
      $.expression,
      repeat($._nl),
      ')',
    ),

    list: $ => delimited($, '[', $.expression, ']'),

    struct_instantiation: $ => seq(
      $.identifier,
      delimited($, '{', $.struct_instantiation_field, '}'),
    ),

    struct_instantiation_field: $ => seq(
      $.identifier,
      repeat($._nl),
      ':',
      repeat($._nl),
      $.expression,
    ),

    // ---------------------------------------------------------------------
    // Literals
    // ---------------------------------------------------------------------

    number: $ => choice(
      $.decimal_number,
      $.hex_number,
      $.octal_number,
      $.binary_number,
    ),

    decimal_number: _ => token(
      /(\d[\d_]*\.?[\d_]*|\.\d[\d_]*)([eE][+-]?\d[\d_]*)?/,
    ),
    hex_number: _ => token(/0x[0-9a-fA-F][0-9a-fA-F_]*/),
    octal_number: _ => token(/0o[0-7][0-7_]*/),
    binary_number: _ => token(/0b[01][01_]*/),

    nan: _ => 'NaN',
    inf: _ => 'inf',

    boolean: _ => choice('true', 'false'),

    typed_hole: _ => '?',

    unicode_exponent: _ => token(/⁻?[¹²³⁴⁵⁶⁷⁸⁹]/),

    _plus: _ => '+',
    _minus: _ => choice('-', '−'),

    identifier: _ => token(seq(
      choice(
        /\p{XID_Start}/,
        /[_%‰°′″$£¥฿]/,
        /[\u20A0-\u20CF]/,
        /[½¼¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]/,
      ),
      repeat(choice(
        /\p{XID_Continue}/,
        /[%‰$£¥฿\u20A0-\u20CF\u2080-\u209C]/,
      )),
    )),

    // ---------------------------------------------------------------------
    // Strings
    // ---------------------------------------------------------------------

    string: $ => choice(
      $.fixed_string,
      $.interpolated_string,
    ),

    fixed_string: $ => seq(
      '"',
      optional($.string_content),
      '"',
    ),

    interpolated_string: $ => seq(
      '"',
      optional($.string_content),
      $.interpolation,
      repeat(seq(optional($.string_content), $.interpolation)),
      optional($.string_content),
      '"',
    ),

    interpolation: $ => seq(
      '{',
      $.expression,
      optional($.format_specifier),
      '}',
    ),

    // Immediate so that `#`, spaces and braces are not mistaken for extras /
    // interpolation delimiters inside a string.
    string_content: _ => token.immediate(prec(1, repeat1(choice(
      /[^"\\{}]/,
      /\\./,
      /\{\{/,
      /\}\}/,
    )))),

    format_specifier: _ => token(seq(':', /[^}"]*/)),
  },
});
