{ self
, inputs
, username
, hostname
, system
, ...
}:
{
  flake.puppeteer-homebrew = { pkgs, ... }: {
    homebrew = {
      enable = true;
      brews = [
        # "winetricks" # game
        # "cabextract" # game
        # "sevenzip" # needed by winetricks
        # "zenity" # game
      ];
      casks = [
        "brave-browser"
        "bitwarden"
        # "hyperkey"
        "karabiner-elements"
        # "heroic" # game
        "steam"
      ];
      onActivation.cleanup = "uninstall";
    };
  };
}
