#!/usr/bin/env nu
# Render a Numbat file with Tree-sitter highlighting and live-preview it.
#
#   preview path/to/file.nbt      # render + serve + open + auto-refresh on save
#   preview --once file.nbt       # render + open the static HTML once
#   preview --no-open file.nbt    # render + serve, but don't launch a browser

def main [
  file: path               # .nbt file to render
  --once                   # render once, don't watch or serve
  --no-open                # don't launch a browser
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

  cd $repo
  let out = $repo | path join ".preview"
  let config = $out | path join "config.json"
  let index = $out | path join "index.html"
  mkdir $out

  # tree-sitter finds the parser by scanning parent dirs for `tree-sitter-*`,
  # and compiles + caches parser.c itself, so there is no dylib to build.
  { "parser-directories": [ ($repo | path dirname) ] }
    | to json --indent 2
    | save --force $config

  # grammar.js -> src/parser.c, then highlight it to HTML.
  let highlight = $"($ts) highlight --config-path '($config)' --html '($file)' > '($index)'"

  if $once {
    ^$ts generate
    ^sh -c $highlight
    if not $no_open {
      if (which open | is-not-empty) { ^open $index } else { ^xdg-open $index }
    }
    return
  }

  # Re-render on change of any input. Watch grammar.js/queries/file, never src/
  # (generate rewrites parser.c, which would feed back into the watcher).
  let grammar = $repo | path join "grammar.js"
  let queries = $repo | path join "queries"
  let render = $"($ts) generate && ($highlight)"
  job spawn {|| ^watchexec -w $file -w $grammar -w $queries -- $render }

  # Serve + refresh in the foreground; Ctrl-C ends the session and the job.
  if $no_open {
    ^live-server $out --host 127.0.0.1
  } else {
    ^live-server $out --host 127.0.0.1 --open
  }
}
