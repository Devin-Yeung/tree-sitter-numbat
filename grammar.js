/**
 * @file Numbat grammar for tree-sitter
 * @author Devin-Yeung
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

export default grammar({
  name: "numbat",

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => "hello"
  }
});
