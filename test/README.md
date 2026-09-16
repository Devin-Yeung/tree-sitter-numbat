# Test corpus

This directory contains the tree-sitter corpus tests for the Numbat grammar.
Each `*.txt` file groups test cases by language feature.

## Format

```
========================================================================
test name
========================================================================

numbat source code

---

(expected syntax tree)
```

## Workflow

The corpus is written **source-first**: every test currently has an empty
expected tree. Once the grammar can parse a file, regenerate the expected
trees with:

```sh
tree-sitter test --update
```

`--update` rewrites every corpus file in place with the parser's current
output. Always review the resulting diff — it captures whatever the grammar
does, including `ERROR` nodes.

Run a single file or a subset of cases with:

```sh
tree-sitter test --file-name expressions.txt
tree-sitter test --include "unicode exponent"
```

See <https://tree-sitter.github.io/tree-sitter/creating-parsers/5-writing-tests.html>
for the full corpus format.

## Reference

The test cases are derived from:

- Numbat's syntax overview: <https://numbat.dev/docs/examples/example-numbat_syntax/>
- Numbat's own parser and tokenizer tests:
  `numbat/src/parser.rs` and `numbat/src/tokenizer.rs`
- The example programs in `examples/` of the Numbat repository.

## Validating snippets

Because the tree-sitter grammar is intentionally more permissive than the
reference implementation in places, it is easy to add a snippet that Numbat
itself rejects. To check that every snippet is at least syntactically valid:

```sh
python3 scripts/check-corpus-syntax.py
```

This runs each snippet through the `numbat` binary with `--no-prelude` and
reports parse errors only (unresolved identifiers and type errors are ignored,
since most snippets are fragments).
