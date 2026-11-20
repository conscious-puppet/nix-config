# ~/.config/rex points straight at this checkout (edits need no switch), and
# the pinned vim-rex-navigator source goes where init.lua looks for it.
{ inputs, config, ... }:
{
  home.file.".config/rex".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/home/rex/config";

  home.file.".local/share/rex/plugins/vim-rex-navigator".source = inputs.vim-rex-navigator;
}
