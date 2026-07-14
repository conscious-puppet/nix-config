
{ pkgs, config, ... }: {
  programs.emacs = {
    enable = true;
    # package = pkgs.emacs-gtk; # Or pkgs.emacs for the basic version
    extraPackages = epkgs: with epkgs; [ solarized-theme nov ];
  };

  xdg.configFile."emacs".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/home/emacs/config";
}
