# Rex configuration, kept in this repo and symlinked into ~/.config/rex the
# same way the Neovim configuration is. Also exposes the pinned
# vim-rex-navigator source at ~/src/vim-rex-navigator, which init.lua's
# package.path points at.
{ inputs, config, ... }:
{
  home.file.".config/rex".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/home/rex/config";

  home.file."src/vim-rex-navigator".source = inputs.vim-rex-navigator;
}
