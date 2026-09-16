{
  pkgs,
  lib,
  config,
  ...
}:

{
  packages = with pkgs; [
    git
    nushell
    tree-sitter
  ];

  scripts.preview = {
    exec = ./scripts/preview.nu;
    package = pkgs.nushell;
    binary = "nu";
    packages = [ pkgs.less ];
    description = "Numbat Tree-sitter highlighting preview (paged in the terminal)";
  };
}
