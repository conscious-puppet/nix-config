# Pinned vim-rex-navigator for Neovim; Rex loads the same source (home/rex).
{ pkgs, inputs }:
pkgs.vimUtils.buildVimPlugin {
  pname = "vim-rex-navigator";
  version = "unstable-2026-10-18";
  src = inputs.vim-rex-navigator;
}
