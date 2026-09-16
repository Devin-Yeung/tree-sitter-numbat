#!/usr/bin/env nu
# Render a Numbat file with Tree-sitter highlighting and page it with less.
#
#   preview path/to/file.nbt

def main [
  file: path               # .nbt file to render
  --ts: string = "tree-sitter"
] {
  # Under devenv the script runs from the nix store, so prefer $DEVENV_ROOT;
  # when run directly, fall back to this file's location.
  let repo = ($env.DEVENV_ROOT? | default ($env.CURRENT_FILE | path dirname | path dirname))
  let file = ($file | path expand)

  if not ($file | path exists) {
    print -e $"error: no such file: ($file)"
    exit 1
  }

  # tree-sitter-config.json holds the theme plus `parser-directories: ["."]`,
  # so highlighting works from inside the repo. tree-sitter compiles and caches
  # parser.c itself, so there is no dylib to build.
  cd $repo
  ^$ts generate
  ^$ts highlight --config-path tree-sitter-config.json $file | ^less -R
}
