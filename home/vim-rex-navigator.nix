# Build the vim-rex-navigator plugin from the flake input so Neovim and the
# Rex configuration (via ~/src/vim-rex-navigator) always run the same pinned
# source.
{ pkgs, inputs }:
pkgs.vimUtils.buildVimPlugin {
  pname = "vim-rex-navigator";
  version = "unstable-2026-10-18";
  src = inputs.vim-rex-navigator;
}
